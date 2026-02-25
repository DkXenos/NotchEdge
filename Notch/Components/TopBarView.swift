//
//  TopBarView.swift
//  Notch
//
//  Top row of the drawer: logo, app name, clock, close button.

import SwiftUI

struct TopBarView: View {
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Logo pill
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(nsColor: .systemPurple), Color(nsColor: .systemBlue)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 20, height: 20)
                .overlay(
                    Text("N")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                )

            Text("Notch")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            // Live clock
            Text(Date(), format: .dateTime.hour().minute())
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))

//            // Close button
//            Button(action: onClose) {
//                Circle()
//                    .fill(.white.opacity(0.14))
//                    .frame(width: 22, height: 22)
//                    .overlay(
//                        Text("✕")
//                            .font(.system(size: 9, weight: .bold))
//                            .foregroundStyle(.white.opacity(0.55))
//                    )
//            }
//            .buttonStyle(.plain)
        }
    }
}

#Preview {
    TopBarView(onClose: {})
        .padding()
        .background(Color(white: 0.1))
}
