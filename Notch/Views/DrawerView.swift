//
//  DrawerView.swift
//  Notch
//
//  Created by Jason TIo on 24/02/26.
//
//  Stage 2 – Paper Flip 3D animation driven by hover / drag.
//  Stage 3 – Frosted-glass background via VisualEffectView (NSVisualEffectView).

import SwiftUI
import AppKit

// MARK: - VisualEffectView
/// Bridges NSVisualEffectView into SwiftUI so we get native frosted-glass blur.
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material     = material
        view.blendingMode = blendingMode
        view.state        = .active
        view.wantsLayer   = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material     = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - DrawerView
/// The visible drawer card.
/// • At rest      → rotated –90° around Y (hidden behind the left edge).
/// • On hover/drag → rotates progressively from –90° to 0°  (fully open).
struct DrawerView: View {

    // ── Constants ────────────────────────────────────────────────────────────
    /// Closed angle stops just short of –90° to avoid a singular projection
    /// matrix (which SwiftUI warns about when the view is perfectly edge-on).
    private static let closedAngle: Double = -89.9
    private static let openAngle:   Double =   0.0

    // ── State ────────────────────────────────────────────────────────────────
    /// Rotation in degrees.  ~–90 = fully hidden, 0 = fully open.
    @State private var rotation: Double = DrawerView.closedAngle
    /// True while the mouse is inside the drawer window.
    @State private var isHovering: Bool = false

    // ── Geometry constants ───────────────────────────────────────────────────
    private let cornerRadius: CGFloat = 16
    private let shadowRadius: CGFloat = 24
    private let perspective: CGFloat  = 1 / 600   // subtle 3-D depth

    // ── Body ─────────────────────────────────────────────────────────────────
    var body: some View {
        ZStack {
            // ── Frosted glass background (Stage 3) ───────────────────────────
            VisualEffectView(
                material:     .hudWindow,
                blendingMode: .behindWindow
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            // ── Drawer content ───────────────────────────────────────────────
            drawerContent
        }
        .frame(
            width:  DrawerWindow.drawerWidth,
            height: DrawerWindow.drawerHeight
        )
        // ── Paper-Flip 3-D rotation (Stage 2) ────────────────────────────────
        // Pivot is the leading (left) edge so it "peels" out from the screen edge.
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 0, y: 1, z: 0),
            anchor: .leading,
            perspective: perspective
        )
        // Drop shadow that appears only when the drawer is open.
        .shadow(
            color: .black.opacity(0.35 * openFraction),
            radius: shadowRadius * openFraction,
            x: 8 * openFraction,
            y: 0
        )
        // ── Hover detection ──────────────────────────────────────────────────
        .onHover { hovering in
            isHovering = hovering
            withAnimation(drawerAnimation(hovering: hovering)) {
                rotation = hovering ? Self.openAngle : Self.closedAngle
            }
        }
        // ── Drag gesture (mouse-drag fallback / fine control) ─────────────────
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Map horizontal drag 0…drawerWidth → closedAngle…openAngle.
                    let fraction = min(max(value.location.x / DrawerWindow.drawerWidth, 0), 1)
                    // Clamp away from exactly –90° to silence the singular-matrix warning.
                    let raw = Double(fraction) * 90 + Self.closedAngle
                    rotation = max(raw, Self.closedAngle)
                }
                .onEnded { value in
                    // Snap: if released past 40% open, finish opening; else close.
                    let fraction = value.location.x / DrawerWindow.drawerWidth
                    withAnimation(drawerAnimation(hovering: fraction > 0.4)) {
                        rotation = fraction > 0.4 ? Self.openAngle : Self.closedAngle
                    }
                }
        )
    }

    // ── Drawer Content ───────────────────────────────────────────────────────
    @ViewBuilder
    private var drawerContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "sidebar.left")
                    .font(.title2)
                    .foregroundStyle(.primary)
                Text("Notch")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.bottom, 4)

            Divider()

            // Placeholder tiles — replace with real widgets
            ForEach(["clock.fill", "calendar", "music.note", "wifi", "bolt.fill"], id: \.self) { icon in
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.body)
                        .frame(width: 28, height: 28)
                        .background(.ultraThinMaterial, in: Circle())
                    Text(icon.capitalized.replacingOccurrences(of: ".fill", with: "")
                                         .replacingOccurrences(of: ".", with: " ")
                                         .capitalized)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Spacer()
        }
        .padding(20)
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    /// 0 when fully closed, 1 when fully open.
    private var openFraction: CGFloat {
        CGFloat((rotation - Self.closedAngle) / (Self.openAngle - Self.closedAngle))
    }

    private func drawerAnimation(hovering: Bool) -> Animation {
        hovering
            ? .spring(response: 0.45, dampingFraction: 0.72)
            : .spring(response: 0.35, dampingFraction: 0.85)
    }
}

// MARK: - Preview
#Preview {
    DrawerView()
        .frame(width: DrawerWindow.drawerWidth, height: DrawerWindow.drawerHeight)
}
