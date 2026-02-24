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
/// The window is intentionally larger than the visible panel by `bleed`
/// on the right and bottom edges so the bouncy spring overshoot never
/// gets clipped by the window boundary. The extra space is fully
/// transparent — no shadow, no background.
class DrawerWindow: NSWindow {

    static let drawerWidth:  CGFloat = 380
    static let drawerHeight: CGFloat = 340
    /// Extra transparent margin so spring overshoot is never clipped.
    static let bleed:        CGFloat = 60

    init(screen: NSScreen) {
        let f = screen.frame
        // Anchor top-left to the screen corner; extend right+down by bleed.
        let contentRect = NSRect(
            x: f.minX,
            y: f.maxY - DrawerWindow.drawerHeight - DrawerWindow.bleed,
            width:  DrawerWindow.drawerWidth  + DrawerWindow.bleed,
            height: DrawerWindow.drawerHeight + DrawerWindow.bleed
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
