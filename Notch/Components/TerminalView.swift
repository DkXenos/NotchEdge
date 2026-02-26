//
//  TerminalView.swift
//  Notch

import SwiftUI

struct TerminalView: View {

    var onBack: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {

            // Top bar
            HStack(spacing: 8) {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.70))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(.white.opacity(0.10)))
                }
                .buttonStyle(.plain)

                HStack(spacing: 5) {
                    Image("terminal")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                        .foregroundStyle(.white.opacity(0.75))
                    Text("Terminal")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 0.5)
                .padding(.horizontal, 12)

            Spacer()

            Text("Terminal coming soon")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white.opacity(0.30))

            Spacer()
        }
    }
}

#Preview {
    TerminalView()
        .frame(width: DrawerWindow.drawerWidth, height: DrawerWindow.drawerHeight)
        .background(Color(white: 0.07))
}
