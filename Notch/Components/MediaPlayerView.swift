//
//  MediaPlayerView.swift
//  Notch
//
//  Album art, track info, and playback controls.
//  Logic is wired up in a later stage — this is a placeholder layout.

import SwiftUI

struct MediaPlayerView: View {
    var body: some View {
        HStack(spacing: 12) {
            // Album art placeholder
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(nsColor: .systemPink), Color(nsColor: .systemPurple)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 48, height: 48)
                .overlay(
                    Text("♪")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.9))
                )

            // Track info
            VStack(alignment: .leading, spacing: 3) {
                Text("Not Playing")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("—")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            // Playback controls
            HStack(spacing: 20) {
                ForEach(["⏮", "▶", "⏭"], id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(width: 28, height: 28)
                }
            }
        }
    }
}

#Preview {
    MediaPlayerView()
        .padding()
        .background(Color(white: 0.1))
}
