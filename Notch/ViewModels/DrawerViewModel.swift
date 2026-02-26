//
//  DrawerViewModel.swift
//  Notch
//
//  Single source of truth for the drawer's open state.
//  DrawerWindowController writes into this; DrawerView reads from it.

import SwiftUI
import Combine

/// Which panel is currently displayed inside the drawer.
enum Panel {
    case home
    case terminal
}

final class DrawerViewModel: ObservableObject {
    /// True when the panel is fully committed open.
    @Published var isOpen: Bool = false

    /// True while the cursor hovers over the trigger zone but the drawer is closed.
    @Published var isPeeking: Bool = false

    /// Live 0…1 scroll progress fed by the controller during an active gesture,
    /// so the panel visually tracks the finger before the threshold is crossed.
    @Published var dragProgress: CGFloat = 0

    /// Which content panel is visible. Defaults to home.
    @Published var activePanel: Panel = .home

    /// Called by the close button inside the view — routes back to the
    /// controller so it can tear down the click-outside monitor.
    var requestClose: (() -> Void)?
}
