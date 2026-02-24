//
//  DrawerView.swift
//  Notch
//

import SwiftUI
import AppKit
import Combine

// MARK: - DrawerViewModel
final class DrawerViewModel: ObservableObject {
    @Published var isOpen:        Bool    = false
    /// Live 0…1 drag progress fed from the controller during a scroll gesture.
    @Published var dragProgress:  CGFloat = 0
    var requestClose: (() -> Void)?
}

// MARK: - VisualEffectView
struct VisualEffectView: NSViewRepresentable {
    var material:     NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material; v.blendingMode = blendingMode
        v.state = .active; v.wantsLayer = true
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material = material; v.blendingMode = blendingMode
    }
}

// MARK: - NotchShape  (sharp top-left, rounded everywhere else)
struct NotchShape: Shape {
    var radius: CGFloat = 20
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: .init(x: rect.minX, y: rect.minY))
        p.addLine(to: .init(x: rect.maxX - radius, y: rect.minY))
        p.addArc(center: .init(x: rect.maxX - radius, y: rect.minY + radius),
                 radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0),   clockwise: false)
        p.addLine(to: .init(x: rect.maxX, y: rect.maxY - radius))
        p.addArc(center: .init(x: rect.maxX - radius, y: rect.maxY - radius),
                 radius: radius, startAngle: .degrees(0),   endAngle: .degrees(90),  clockwise: false)
        p.addLine(to: .init(x: rect.minX + radius, y: rect.maxY))
        p.addArc(center: .init(x: rect.minX + radius, y: rect.maxY - radius),
                 radius: radius, startAngle: .degrees(90),  endAngle: .degrees(180), clockwise: false)
        p.addLine(to: .init(x: rect.minX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - DrawerView
struct DrawerView: View {

    @ObservedObject var viewModel: DrawerViewModel

    // 0 = closed, 1 = fully open — driven by both snap animation and live drag
    @State private var progress: CGFloat = 0

    var body: some View {
        panelContent
            // ── Scale from top-left corner ────────────────────────────────────
            .scaleEffect(
                x: 0.10 + 0.90 * progress,
                y: 0.10 + 0.90 * progress,
                anchor: .topLeading
            )
            // ── Diagonal slide: peels out of the top-left corner ──────────────
            .offset(x: -20 * (1 - progress),
                    y: -24 * (1 - progress))
            // ── Perspective shear (reduces as it opens) ───────────────────────
            .transformEffect(shear)
            // ── Fade ──────────────────────────────────────────────────────────
            .opacity(Double(max(progress, 0.01)))  // never fully 0 so layout stays
            // ── Sync on first appear (fixes blank preview) ────────────────────
            .onAppear {
                progress = viewModel.isOpen ? 1 : 0
            }
            // ── Snap animation when isOpen toggles ────────────────────────────
            .onChange(of: viewModel.isOpen) { _, open in
                withAnimation(open
                    ? .spring(response: 0.50, dampingFraction: 0.60)
                    : .spring(response: 0.28, dampingFraction: 0.88)
                ) {
                    progress = open ? 1 : 0
                }
            }
            // ── Live drag: no animation, just track finger ────────────────────
            .onChange(of: viewModel.dragProgress) { _, p in
                guard !viewModel.isOpen else { return }
                progress = p
            }
    }

    // Mild shear that vanishes when fully open
    private var shear: CGAffineTransform {
        let t = Double(progress)
        return CGAffineTransform(a: 1, b: CGFloat(0.04*(1-t)),
                                 c: CGFloat(0.05*(1-t)), d: 1,
                                 tx: 0, ty: 0)
    }

    // MARK: - Glass panel ─────────────────────────────────────────────────────
    private var panelContent: some View {
        ZStack(alignment: .topLeading) {
            // 1. Blur base
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(NotchShape(radius: 20))
            // 2. Dark tint for readability
            NotchShape(radius: 20)
                .fill(Color(white: 0, opacity: 0.52))
            // 3. Specular top-left shimmer
            NotchShape(radius: 20)
                .fill(LinearGradient(stops: [
                    .init(color: .white.opacity(0.20), location: 0.00),
                    .init(color: .white.opacity(0.07), location: 0.25),
                    .init(color: .clear,               location: 0.55),
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
            // 4. Hair-line rim
            NotchShape(radius: 20)
                .stroke(LinearGradient(
                    colors: [.white.opacity(0.40), .white.opacity(0.04)],
                    startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.75)
            // 5. Content
            notchContent
        }
        .frame(width: DrawerWindow.drawerWidth, height: DrawerWindow.drawerHeight)
        .shadow(color: .black.opacity(0.55 * progress),
                radius: 36 * progress, x: 4 * progress, y: 8 * progress)
    }

    // MARK: - Content ─────────────────────────────────────────────────────────
    @ViewBuilder
    private var notchContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)
            div
            mediaPlayer
                .padding(.horizontal, 16).padding(.vertical, 14)
            div
            actionButtons
                .padding(.horizontal, 16).padding(.vertical, 12)
            div
            launchpadGrid
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 14)
        }
    }

    private var div: some View {
        Rectangle().fill(.white.opacity(0.10)).frame(height: 0.5).padding(.horizontal, 12)
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack(spacing: 8) {
            // Logo pill
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(LinearGradient(colors: [Color(nsColor: .systemPurple), Color(nsColor: .systemBlue)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 20, height: 20)
                .overlay(Text("N").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(.white))
            Text("Notch")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Text(Date(), format: .dateTime.hour().minute())
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
            Button { viewModel.requestClose?() } label: {
                Circle().fill(.white.opacity(0.14)).frame(width: 22, height: 22)
                    .overlay(Text("✕").font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.55)))
            }.buttonStyle(.plain)
        }
    }

    // MARK: - Media player
    private var mediaPlayer: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(LinearGradient(colors: [Color(nsColor: .systemPink), Color(nsColor: .systemPurple)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 48, height: 48)
                .overlay(Text("♪").font(.system(size: 20)).foregroundStyle(.white.opacity(0.9)))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            VStack(alignment: .leading, spacing: 3) {
                Text("Not Playing")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white).lineLimit(1)
                Text("—")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            HStack(spacing: 20) {
                ForEach(["⏮", "▶", "⏭"], id: \.self) { sym in
                    Text(sym).font(.system(size: 15)).foregroundStyle(.white.opacity(0.75))
                        .frame(width: 28, height: 28)
                }
            }
        }
    }

    // MARK: - Action buttons (text labels only, no risky SF symbols)
    private let actions = ["Wi-Fi", "BT", "AirPlay", "Focus", "Mirror"]

    private var actionButtons: some View {
        HStack(spacing: 0) {
            ForEach(actions, id: \.self) { label in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.11))
                        .frame(width: 50, height: 34)
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 0.5))
                        .overlay(Text(label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85)))
                }
                if label != actions.last { Spacer() }
            }
        }
    }

    // MARK: - Launchpad (text only)
    private let appLabels = [
        "Safari", "Mail",   "Notes",  "Cal",
        "Maps",   "Music",  "Photos", "Term",
        "Files",  "News",   "Stocks", "Trash",
    ]
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    private var launchpadGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Launchpad")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.40))
                Spacer()
                Text("↗").font(.system(size: 10)).foregroundStyle(.white.opacity(0.22))
            }
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(appLabels, id: \.self) { name in
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(.white.opacity(0.09))
                        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 0.5))
                        .frame(width: 38, height: 38)
                        .overlay(Text(name)
                            .font(.system(size: 7.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.70))
                            .multilineTextAlignment(.center)
                            .lineLimit(2))
                }
            }
        }
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
