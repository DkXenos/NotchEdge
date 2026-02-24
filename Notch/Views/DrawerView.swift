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
        // Transparent canvas the exact size of the window.
        // The panel sits in the top-leading corner; everything else is clear.
        Color.clear
            .overlay(alignment: .topLeading) {
                glassPanel
                    .scaleEffect(
                        x: 0.10 + 0.90 * progress,
                        y: 0.10 + 0.90 * progress,
                        anchor: .topLeading
                    )
                    .offset(x: -20 * (1 - progress), y: -24 * (1 - progress))
                    .opacity(Double(progress))
            }
            .onAppear {
                progress = viewModel.isOpen ? 1 : 0
            }
            .onChange(of: viewModel.isOpen) { _, open in
                withAnimation(
                    open
                        ? .spring(response: 0.45, dampingFraction: 0.62)
                        : .spring(response: 0.26, dampingFraction: 0.90)
                ) {
                    progress = open ? 1 : 0
                }
            }
            .onChange(of: viewModel.dragProgress) { _, p in
                guard !viewModel.isOpen else { return }
                progress = p
            }
    }

    // MARK: - Glass panel
    /// A single ZStack clipped to NotchShape.
    /// No .shadow(), no .compositingGroup(), no bleed padding —
    /// those were the sources of the black rectangle artifact.
    private var glassPanel: some View {
        ZStack(alignment: .topLeading) {
            // 1. Behind-window blur — clipped to the notch shape at the
            //    SwiftUI level. No wantsLayer on the NSVisualEffectView so
            //    AppKit never inserts an opaque backing CALayer.
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)

            // 2. Dark tint for legibility
            Color.black.opacity(0.52)

            // 3. Specular highlight
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.18), location: 0.00),
                    .init(color: .white.opacity(0.06), location: 0.30),
                    .init(color: .clear,               location: 0.60),
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )

            // 4. Content
            panelContent
        }
        // Single clip — applied once, at the outermost level.
        // This correctly masks every layer above, including the blur.
        .clipShape(NotchShape(radius: 20))
        // Hair-line rim drawn on top of the clip so it sits on the edge.
        .overlay(
            NotchShape(radius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.35), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        )
        .frame(width: DrawerWindow.drawerWidth, height: DrawerWindow.drawerHeight)
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
        .frame(width: DrawerWindow.drawerWidth, height: DrawerWindow.drawerHeight)
        .background(Color(white: 0.07))
}
