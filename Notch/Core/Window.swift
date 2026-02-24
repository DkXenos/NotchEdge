//
//  Window.swift
//  Notch
//
//  Created by Jason TIo on 24/02/26.
//

import AppKit
import SwiftUI

// MARK: - TriggerWindow
/// A 1-pixel-wide invisible window that covers the full height of the leftmost
/// screen edge. It captures mouse-entered events and forwards them to the
/// DrawerWindowController so the drawer can open.
class TriggerWindow: NSWindow {
    init(screen: NSScreen) {
        let screenFrame = screen.frame
        let triggerRect = NSRect(
            x: screenFrame.minX,
            y: screenFrame.minY,
            width: 1,
            height: screenFrame.height
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
/// The actual panel that slides/flips out from the left edge.
/// It is transparent and hosts a SwiftUI view.
class DrawerWindow: NSWindow {
    static let drawerWidth: CGFloat  = 300
    static let drawerHeight: CGFloat = 520

    init(screen: NSScreen) {
        let screenFrame = screen.frame
        let x = screenFrame.minX                                    // starts flush with left edge
        let y = screenFrame.minY + (screenFrame.height - DrawerWindow.drawerHeight) / 2

        let contentRect = NSRect(
            x: x,
            y: y,
            width: DrawerWindow.drawerWidth,
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
