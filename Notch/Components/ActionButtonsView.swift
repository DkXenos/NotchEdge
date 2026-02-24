//
//  ActionButtonsView.swift
//  Notch
//
//  Row of quick-toggle chips (Wi-Fi, BT, AirPlay, Focus, Mirror).
//  Toggle logic wired up in a later stage — layout placeholder for now.

import SwiftUI

struct ActionButtonsView: View {
    private let actions = ["Wi-Fi", "BT", "AirPlay", "Focus", "Mirror"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(actions, id: \.self) { label in
                ActionChip(label: label)
                if label != actions.last {
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Single chip
private struct ActionChip: View {
    let label: String

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.white.opacity(0.11))
            .frame(width: 50, height: 34)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 0.5)
            )
            .overlay(
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            )
    }
}

#Preview {
    ActionButtonsView()
        .padding()
        .background(Color(white: 0.1))
}
