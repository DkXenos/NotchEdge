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
/// The notch panel that flips down from the top-left corner.
/// Transparent, hosts a SwiftUI view.
class DrawerWindow: NSWindow {
    static let drawerWidth:  CGFloat = 380
    static let drawerHeight: CGFloat = 340

    init(screen: NSScreen) {
        let screenFrame = screen.frame
        let x = screenFrame.minX                              // flush with left edge
        let y = screenFrame.maxY - DrawerWindow.drawerHeight  // pinned to top

        let contentRect = NSRect(
            x: x,
            y: y,
            width:   DrawerWindow.drawerWidth,
            height: DrawerWindow.drawerHeight
        )
        super.init(
            contentRect: contentRect,
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
        hasShadow = false          // shadow is handled by the SwiftUI layer
        acceptsMouseMovedEvents = true
    }

    // Allow the window to become key so hover/keyboard events work correctly.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
