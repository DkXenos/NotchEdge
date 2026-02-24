//
//  DrawerWindowController.swift
//  Notch
//
//  Created by Jason TIo on 24/02/26.
//
//  Listens for two-finger scroll in the top-left hot-zone:
//   • Scroll down  → drags the panel open live, commits when threshold reached
//   • Scroll up    → closes
//   • Click outside → closes

import AppKit
import SwiftUI
import Combine

final class DrawerWindowController: NSObject {

    // MARK: - Window
    private var drawerWindow: DrawerWindow!

    // MARK: - State
    private(set) var isOpen = false

    // MARK: - Monitors
    private var globalScrollMonitor: Any?
    private var localScrollMonitor:  Any?
    private var clickMonitor:        Any?

    // MARK: - Callbacks → SwiftUI
    /// Called with true/false to snap open/close with animation.
    var onOpenChanged: ((Bool) -> Void)?
    /// Called with 0…1 during an active drag so progress tracks the finger.
    var onDragProgress: ((CGFloat) -> Void)?

    // MARK: - Scroll accumulator
    private var scrollAccum:    CGFloat = 0
    private var resetWorkItem:  DispatchWorkItem?

    // MARK: - Hot-zone (top-left strip the cursor must be in)
    private var hotZone: NSRect {
        guard let s = NSScreen.main ?? NSScreen.screens.first else { return .zero }
        return NSRect(x: s.frame.minX,
                      y: s.frame.maxY - 80,
                      width: DrawerWindow.drawerWidth,
                      height: 80)
    }

    // MARK: - Init
    override init() {
        super.init()
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        buildDrawerWindow(on: screen)
        installMonitors()
    }

    deinit {
        [globalScrollMonitor, localScrollMonitor, clickMonitor]
            .compactMap { $0 }
            .forEach { NSEvent.removeMonitor($0) }
    }

    // MARK: - Window setup
    private func buildDrawerWindow(on screen: NSScreen) {
        drawerWindow = DrawerWindow(screen: screen)

        let vm = DrawerViewModel()
        vm.requestClose = { [weak self] in self?.setOpen(false) }

        let root = DrawerView(viewModel: vm)
        let host = NSHostingView(rootView: root)
        host.frame = drawerWindow.contentView!.bounds
        host.autoresizingMask = [.width, .height]

        // ── Kill every background that could paint a dark rectangle ───────────
        host.wantsLayer = true
        host.layer?.backgroundColor = CGColor.clear
        host.layer?.isOpaque        = false
        // Disable the hosting view's own clipping so scale animations
        // that grow beyond the panel rect are never clipped.
        host.layer?.masksToBounds   = false

        drawerWindow.contentView?.wantsLayer    = true
        drawerWindow.contentView?.layer?.backgroundColor = CGColor.clear
        drawerWindow.contentView?.layer?.isOpaque        = false
        drawerWindow.contentView?.layer?.masksToBounds   = false

        drawerWindow.contentView = host
        drawerWindow.orderFrontRegardless()

        onOpenChanged  = { [weak vm] open     in vm?.isOpen   = open }
        onDragProgress = { [weak vm] progress in vm?.dragProgress = progress }
    }

    // MARK: - Monitors
    private func installMonitors() {
        // Global monitor catches events when another app is frontmost.
        globalScrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] e in
            self?.handleScroll(e)
        }
        // Local monitor catches events when our own (invisible) window is active.
        localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] e in
            self?.handleScroll(e)
            return e
        }
    }

    // MARK: - Scroll handling
    private func handleScroll(_ event: NSEvent) {
        // Only react to active trackpad touch (not inertia / mouse wheel).
        // event.phase == [] means "no phase info" (mouse wheel or momentum end).
        let isTrackpad = !event.phase.isEmpty || !event.momentumPhase.isEmpty
        guard isTrackpad else { return }

        let mouse = NSEvent.mouseLocation
        let inZone = hotZone.contains(mouse)

        // If cursor is outside zone and drawer is closed, ignore completely.
        guard inZone || isOpen else { return }

        let delta = event.scrollingDeltaY   // +ve = natural scroll down

        // ── Live drag progress ────────────────────────────────────────────────
        // Accumulate delta and emit a 0…1 progress so the panel tracks finger.
        scrollAccum += delta

        resetWorkItem?.cancel()
        let reset = DispatchWorkItem { [weak self] in self?.scrollAccum = 0 }
        resetWorkItem = reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: reset)

        if !isOpen {
            // Map 0…60 pts of downward scroll → 0…1 drag progress
            let drag = max(0, min(scrollAccum / 60, 1))
            DispatchQueue.main.async { [weak self] in
                self?.onDragProgress?(drag)
            }
            // Commit open when threshold crossed
            if scrollAccum >= 55 {
                scrollAccum = 0
                setOpen(true)
                installClickOutsideMonitor()
            }
        } else {
            // While open, map upward scroll to closing progress
            if delta < 0 {
                let drag = max(0, min(1 + scrollAccum / 40, 1))
                DispatchQueue.main.async { [weak self] in
                    self?.onDragProgress?(drag)
                }
                if scrollAccum <= -35 {
                    scrollAccum = 0
                    setOpen(false)
                }
            }
        }

        // End of gesture phase: snap to nearest state
        if event.phase == .ended || event.phase == .cancelled {
            scrollAccum = 0
            let shouldOpen = isOpen ? true : false   // keep current committed state
            DispatchQueue.main.async { [weak self] in
                self?.onOpenChanged?(shouldOpen)
            }
        }
    }

    // MARK: - Click-outside monitor
    private func installClickOutsideMonitor() {
        guard clickMonitor == nil else { return }
        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            guard let self else { return }
            if !self.drawerWindow.frame.contains(NSEvent.mouseLocation) {
                self.setOpen(false)
            }
        }
    }

    private func removeClickMonitor() {
        if let m = clickMonitor { NSEvent.removeMonitor(m) }
        clickMonitor = nil
    }

    // MARK: - Open / close
    func setOpen(_ open: Bool) {
        isOpen = open
        DispatchQueue.main.async { [weak self] in
            self?.onOpenChanged?(open)
        }
        if !open { removeClickMonitor() }
    }
}
