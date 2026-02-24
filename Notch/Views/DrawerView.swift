//
//  DrawerView.swift
//  Notch
//
//  Thin coordinator view — owns only:
//    • The glass panel shell (NotchShape layers)
//    • The open/close animation (scale + offset + shear + opacity)
//  All content sections live in Components/.
//  Utilities (VisualEffectView, NotchShape) live in Utilities/.
//  State lives in ViewModels/DrawerViewModel.swift.

import SwiftUI
import AppKit

struct DrawerView: View {

    @ObservedObject var viewModel: DrawerViewModel

    /// 0 = fully closed, 1 = fully open.
    /// Driven by snap animations (isOpen) and live drag (dragProgress).
    @State private var progress: CGFloat = 0

    // MARK: - Body
    var body: some View {
        glassPanel
            // ── Scale from top-left corner ────────────────────────────────────
            .scaleEffect(
                x: 0.10 + 0.90 * progress,
                y: 0.10 + 0.90 * progress,
                anchor: .topLeading
            )
            // ── Diagonal offset: peels out of the screen corner ───────────────
            .offset(
                x: -20 * (1 - progress),
                y: -24 * (1 - progress)
            )
            // ── Perspective shear: dissolves as the panel fully opens ─────────
            .transformEffect(perspectiveShear)
            // ── Opacity: true zero when closed — no dark ghost at 0.01 ────────
            .opacity(Double(progress))
            // ── Sync initial state (fixes blank Xcode preview) ────────────────
            .onAppear {
                progress = viewModel.isOpen ? 1 : 0
            }
            // ── Snap animation when controller commits open/close ─────────────
            .onChange(of: viewModel.isOpen) { _, open in
                withAnimation(
                    open
                        ? .spring(response: 0.50, dampingFraction: 0.60)
                        : .spring(response: 0.28, dampingFraction: 0.88)
                ) {
                    progress = open ? 1 : 0
                }
            }
            // ── Live drag: no animation, panel tracks finger directly ─────────
            .onChange(of: viewModel.dragProgress) { _, p in
                guard !viewModel.isOpen else { return }
                progress = p
            }
    }

    // MARK: - Perspective shear
    /// Mild top-left-anchored taper that collapses to identity when fully open.
    private var perspectiveShear: CGAffineTransform {
        let t = Double(progress)
        return CGAffineTransform(
            a: 1,   b: CGFloat(0.04 * (1 - t)),
            c: CGFloat(0.05 * (1 - t)), d: 1,
            tx: 0,  ty: 0
        )
    }

    // MARK: - Glass panel shell
    /// Layered ZStack that produces the liquid-glass look, with bleed padding
    /// so the scale animation never clips at the window boundary.
    private var glassPanel: some View {
        ZStack(alignment: .topLeading) {
            // 1. System blur — OUTSIDE drawingGroup so the live compositor
            //    can do the actual blur pass against the wallpaper/windows.
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(NotchShape(radius: 20))

            // 2-5: Tint + shimmer + rim + content are rasterised together so
            //      the shear/scale transforms have clean sub-pixel edges.
            ZStack(alignment: .topLeading) {
                // 2. Dark tint for legibility
                NotchShape(radius: 20)
                    .fill(Color(white: 0, opacity: 0.52))

                // 3. Specular highlight (top-left shimmer)
                NotchShape(radius: 20)
                    .fill(LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.20), location: 0.00),
                            .init(color: .white.opacity(0.07), location: 0.25),
                            .init(color: .clear,               location: 0.55),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

                // 4. Hair-line inner rim
                NotchShape(radius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.40), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )

                // 5. Content sections
                panelContent
            }
            // Rasterise only these non-blur layers into a Metal texture.
            // This fixes sub-pixel aliasing on the shear/scale transforms
            // without breaking NSVisualEffectView's live blur.
            .drawingGroup(opaque: false)
        }
        .frame(width: DrawerWindow.drawerWidth, height: DrawerWindow.drawerHeight)
        // Bleed padding so the scale animation never clips at the window edge
        .padding(DrawerWindow.bleed)
        .frame(
            width:  DrawerWindow.drawerWidth  + DrawerWindow.bleed * 2,
            height: DrawerWindow.drawerHeight + DrawerWindow.bleed * 2,
            alignment: .topLeading
        )
        // Shadow is zero when closed — no dark ghost
        .shadow(
            color:  .black.opacity(0.50 * progress),
            radius: 32 * progress,
            x:       4 * progress,
            y:       8 * progress
        )
    }

    // MARK: - Content layout
    /// Stacks the four component sections with glass dividers between them.
    private var panelContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            TopBarView(onClose: { viewModel.requestClose?() })
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            GlassDivider()

            MediaPlayerView()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

            GlassDivider()

            ActionButtonsView()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            GlassDivider()

            LaunchpadGridView()
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 14)
        }
    }
}

// MARK: - GlassDivider
/// Thin semi-transparent line separating content sections.
private struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.10))
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }
}

// MARK: - Preview
#Preview {
    let vm = DrawerViewModel()
    vm.isOpen = true
    return DrawerView(viewModel: vm)
        .frame(
            width:  DrawerWindow.drawerWidth  + DrawerWindow.bleed * 2,
            height: DrawerWindow.drawerHeight + DrawerWindow.bleed * 2
        )
        .background(Color(white: 0.07))
}
