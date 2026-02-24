//
//  DrawerViewModel.swift
//  Notch
//
//  Single source of truth for the drawer's open state.
//  DrawerWindowController writes into this; DrawerView reads from it.

import SwiftUI
import Combine

final class DrawerViewModel: ObservableObject {
    /// True when the panel is fully committed open.
    @Published var isOpen: Bool = false

    /// Live 0…1 scroll progress fed by the controller during an active gesture,
    /// so the panel visually tracks the finger before the threshold is crossed.
    @Published var dragProgress: CGFloat = 0

    /// Called by the close button inside the view — routes back to the
    /// controller so it can tear down the click-outside monitor.
    var requestClose: (() -> Void)?
}
