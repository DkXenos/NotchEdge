//
//  Window.swift
//  Notch
//
//  Created by Jason TIo on 24/02/26.
//

import AppKit
import SwiftUI

// MARK: - TriggerWindow
/// A 1-pixel-tall invisible window that covers the top-left corner of the screen.
/// It captures mouse-entered events and forwards them to the DrawerWindowController.
class TriggerWindow: NSWindow {
    init(screen: NSScreen) {
        let screenFrame = screen.frame
        let triggerRect = NSRect(
            x: screenFrame.minX,
            y: screenFrame.maxY - 1,          // top-left, 1 px tall
            width: DrawerWindow.drawerWidth,   // same width as the drawer
            height: 1
        )
        super.init(
            contentRect: triggerRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = false
        isReleasedWhenClosed = false
        // Accept mouse-moved events so onHover works in hosted SwiftUI views.
        acceptsMouseMovedEvents = true
    }
}

// MARK: - DrawerWindow
/// Borderless, fully transparent window that hosts the notch panel.
/// Sized exactly to the panel — no bleed padding needed because the
/// SwiftUI view's Color.clear background handles the surrounding space.
class DrawerWindow: NSWindow {

    static let drawerWidth:  CGFloat = 380
    static let drawerHeight: CGFloat = 340

    init(screen: NSScreen) {
        let f = screen.frame
        // Top-left corner of the screen, exactly panel-sized.
        let contentRect = NSRect(
            x: f.minX,
            y: f.maxY - DrawerWindow.drawerHeight,
            width:  DrawerWindow.drawerWidth,
            height: DrawerWindow.drawerHeight
        )
        super.init(
            contentRect:  contentRect,
            styleMask:    [.borderless],
            backing:      .buffered,
            defer:        false
        )
        // ── Transparency ──────────────────────────────────────────────────────
        // These three lines are the ONLY thing needed to get a fully transparent
        // window. Do NOT set them on the contentView or its layer — AppKit
        // manages those automatically once the window is transparent.
        isOpaque        = false
        backgroundColor = .clear
        hasShadow       = false

        // ── Behaviour ─────────────────────────────────────────────────────────
        level                = .screenSaver
        collectionBehavior   = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents   = false
        isReleasedWhenClosed = false
        acceptsMouseMovedEvents = true
    }

    override var canBecomeKey:  Bool { true  }
    override var canBecomeMain: Bool { false }
}
