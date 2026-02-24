//
//  VisualEffectView.swift
//  Notch
//
//  Minimal NSVisualEffectView wrapper for SwiftUI.
//
//  Rules:
//  • Do NOT set wantsLayer = true — NSVisualEffectView manages its own
//    internal CALayer hierarchy. An extra backing layer causes an opaque
//    black rectangle to appear behind the blur.
//  • Do NOT apply a CAShapeLayer mask here — SwiftUI's .clipShape() on
//    the parent ZStack clips the blur cleanly when wantsLayer is not forced.
//  • Do NOT set any shadow properties — hasShadow=false on the window is
//    the single source of truth for shadow suppression.

import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
    var material:     NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v          = NSVisualEffectView()
        v.material     = material
        v.blendingMode = blendingMode
        v.state        = .active
        return v
    }

    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material     = material
        v.blendingMode = blendingMode
    }
}
