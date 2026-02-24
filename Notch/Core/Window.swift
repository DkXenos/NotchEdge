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
/// The notch panel that drops from the top-left corner.
/// The window is intentionally LARGER than the visible panel so the
/// scale/offset animation never clips at the window edge.
class DrawerWindow: NSWindow {
    static let drawerWidth:  CGFloat = 380
    static let drawerHeight: CGFloat = 340

    /// Extra transparent bleed around the panel so animations never clip.
    static let bleed: CGFloat = 40

    init(screen: NSScreen) {
        let screenFrame = screen.frame
        // Shift left/up by bleed so the panel's top-left corner sits at (0,0)
        // of the screen, while the window itself extends slightly off-screen.
        let x = screenFrame.minX - DrawerWindow.bleed
        let y = screenFrame.maxY - DrawerWindow.drawerHeight - DrawerWindow.bleed

        let contentRect = NSRect(
            x: x,
            y: y,
            width:  DrawerWindow.drawerWidth  + DrawerWindow.bleed * 2,
            height: DrawerWindow.drawerHeight + DrawerWindow.bleed * 2
        )
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isOpaque            = false
        backgroundColor     = .clear
        level               = .screenSaver
        collectionBehavior  = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents  = false
        isReleasedWhenClosed = false
        hasShadow           = false
        acceptsMouseMovedEvents = true
    }

    override var canBecomeKey:  Bool { true  }
    override var canBecomeMain: Bool { false }
}
