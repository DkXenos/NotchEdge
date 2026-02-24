//
//  NotchApp.swift
//  Notch
//
//  Created by Jason TIo on 24/02/26.
//

import SwiftUI
import AppKit

// MARK: - App Entry Point
@main
struct NotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No default window — the AppDelegate manages everything.
        Settings { EmptyView() }
    }
}

// MARK: - AppDelegate
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var drawerController: DrawerWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Close any window Xcode/SwiftUI may have created automatically.
        NSApp.windows.forEach { $0.close() }

        // Build the trigger strip + drawer panel.
        drawerController = DrawerWindowController()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // LSUIElement apps must NOT quit when windows are closed.
        false
    }
}
