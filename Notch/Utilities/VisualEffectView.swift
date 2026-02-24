//
//  VisualEffectView.swift
//  Notch
//
//  NSVisualEffectView wrapper for SwiftUI — provides the system blur/vibrancy
//  that makes the glass surface read correctly against any wallpaper.

import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
    var material:     NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material     = material
        v.blendingMode = blendingMode
        v.state        = .active
        v.wantsLayer   = true
        return v
    }

    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material     = material
        v.blendingMode = blendingMode
    }
}
