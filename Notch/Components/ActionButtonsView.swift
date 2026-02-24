//
//  ActionButtonsView.swift
//  Notch
//
//  Row of 5 quick-action chips using the real asset icons.
//  Tapping Terminal switches the drawer to the terminal panel.

import SwiftUI

struct ActionButtonsView: View {
    /// Callback fired when the Terminal chip is tapped.
    var onTerminalTap: (() -> Void)? = nil

    struct Action: Identifiable {
        let id    = UUID()
        let asset: String   // name in Assets.xcassets
        let label: String
        let isTerminal: Bool
    }

    private let actions: [Action] = [
        .init(asset: "wifi",       label: "Wi-Fi",      isTerminal: false),
        .init(asset: "bluetooth",  label: "BT",         isTerminal: false),
        .init(asset: "airdrop",    label: "AirDrop",    isTerminal: false),
        .init(asset: "screenshot", label: "Screenshot", isTerminal: false),
        .init(asset: "terminal",   label: "Terminal",   isTerminal: true),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(actions) { action in
                ActionChip(action: action) {
                    if action.isTerminal { onTerminalTap?() }
                }
                if action.id != actions.last?.id {
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Single chip
private struct ActionChip: View {
    let action: ActionButtonsView.Action
    let onTap: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Image(action.asset)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.white.opacity(0.90))
                Text(action.label)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .frame(width: 54, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(pressed ? 0.20 : 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 0.5)
            )
            .scaleEffect(pressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.1)) { pressed = true  } }
                .onEnded   { _ in withAnimation(.spring(response: 0.3))  { pressed = false } }
        )
    }
}

#Preview {
    ActionButtonsView()
        .padding()
        .background(Color(white: 0.1))
}
