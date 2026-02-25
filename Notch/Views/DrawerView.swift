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
            Color.black.opacity(1)

            // 3. Specular highlight
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0), location: 0.00),
                    .init(color: .white.opacity(0), location: 0.30),
                    .init(color: .clear,               location: 0.60),
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )

            // 4. Content — switches between home and terminal panels
            panelSwitcher
        }
        // Single clip at the outermost level.
        .clipShape(NotchShape(radius: 20))
        // Hair-line rim on top of the clip.
        .overlay(
            NotchShape(radius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0), .white.opacity(0)],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        )
        .frame(width: DrawerWindow.drawerWidth, height: DrawerWindow.drawerHeight)
    }

    // MARK: - Panel switcher
    @ViewBuilder
    private var panelSwitcher: some View {
        ZStack {
            if viewModel.activePanel == .home {
                homeContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                TerminalView(onBack: {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        viewModel.activePanel = .home
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: viewModel.activePanel)
    }

    // MARK: - Home content
    private var homeContent: some View {
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

            ActionButtonsView(onTerminalTap: {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    viewModel.activePanel = .terminal
                }
            })
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
