//
//  DrawerWindowController.swift
//  Notch
//
//  Created by Jason TIo on 24/02/26.
//
//  Owns both the 1-px TriggerWindow and the DrawerWindow.
//  When the cursor enters the trigger strip the drawer window is made key
//  and the SwiftUI onHover fires, starting the flip animation.

import AppKit
import SwiftUI

final class DrawerWindowController: NSObject {

    // MARK: - Owned windows
    private var triggerWindow: TriggerWindow!
    private var drawerWindow:  DrawerWindow!

    // MARK: - Init
    override init() {
        super.init()
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            assertionFailure("No screen found – cannot create drawer windows.")
            return
        }
        buildWindows(on: screen)
    }

    // MARK: - Setup
    private func buildWindows(on screen: NSScreen) {

        // ── DrawerWindow ──────────────────────────────────────────────────────
        drawerWindow = DrawerWindow(screen: screen)

        // Host the SwiftUI DrawerView inside the drawer window.
        let drawerView  = DrawerView()
        let hostingView = NSHostingView(rootView: drawerView)
        hostingView.frame = drawerWindow.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]
        drawerWindow.contentView = hostingView
        drawerWindow.orderFrontRegardless()

        // ── TriggerWindow ─────────────────────────────────────────────────────
        triggerWindow = TriggerWindow(screen: screen)

        // A tiny invisible SwiftUI view that listens for hover and tells the
        // drawer window to become key so its own hover tracking activates.
        let triggerView = TriggerHotZoneView { [weak self] entered in
            guard let self else { return }
            if entered {
                self.drawerWindow.makeKeyAndOrderFront(nil)
            }
        }
        let triggerHost = NSHostingView(rootView: triggerView)
        triggerHost.frame = triggerWindow.contentView!.bounds
        triggerHost.autoresizingMask = [.width, .height]
        triggerWindow.contentView = triggerHost
        triggerWindow.orderFrontRegardless()
    }
}

// MARK: - TriggerHotZoneView
/// A completely transparent SwiftUI view occupying the 1-px TriggerWindow.
/// It fires a callback when the cursor enters / exits.
private struct TriggerHotZoneView: View {
    var onHover: (Bool) -> Void

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onHover { hovering in
                onHover(hovering)
            }
    }
}
