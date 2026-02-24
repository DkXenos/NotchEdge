//
//  LaunchpadGridView.swift
//  Notch
//
//  6-column mini app grid. App launching logic wired up in a later stage —
//  text-label placeholders for now.

import SwiftUI

struct LaunchpadGridView: View {
    private let appLabels = [
        "Safari", "Mail",   "Notes",  "Cal",
        "Maps",   "Music",  "Photos", "Term",
        "Files",  "News",   "Stocks", "Trash",
    ]

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 6
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Text("Launchpad")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.40))
                Spacer()
                Text("↗")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.22))
            }

            // Grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(appLabels, id: \.self) { name in
                    AppCell(name: name)
                }
            }
        }
    }
}

// MARK: - Single cell
private struct AppCell: View {
    let name: String

    var body: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(.white.opacity(0.09))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 0.5)
            )
            .frame(width: 38, height: 38)
            .overlay(
                Text(name)
                    .font(.system(size: 7.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            )
    }
}

#Preview {
    LaunchpadGridView()
        .padding()
        .background(Color(white: 0.1))
}
