//
//  PeekView.swift
//  Notch
//
//  A small pill that slides down from the top-left corner when the cursor
//  enters the trigger hot-zone. Shows the app icon as a subtle "peek"
//  affordance before the full drawer opens.
//

import SwiftUI

struct PeekView: View {

    /// Driven by DrawerViewModel.isPeeking via the controller.
    var isPeeking: Bool

    /// 0 = hidden (off-screen), 1 = fully visible.
    @State private var visibility: CGFloat = 0

    var body: some View {
        ZStack {
            // ── Pill background ───────────────────────────────────────────────
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: PeekWindow.peekHeight / 2,
                topTrailingRadius: PeekWindow.peekHeight / 2,
                style: .continuous
            )
            .fill(Color.clear)

            // ── Subtle inner highlight ────────────────────────────────────────
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: PeekWindow.peekHeight / 2,
                topTrailingRadius: PeekWindow.peekHeight / 2,
                style: .continuous
            )
            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.75)

            // ── Content ───────────────────────────────────────────────────────
            HStack(spacing: 6) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                Text("Notch")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
        }
        // Slide down from behind the menu bar
        .offset(y: (1 - visibility) * -PeekWindow.peekHeight)
        .opacity(Double(visibility))
        .frame(width: PeekWindow.peekWidth, height: PeekWindow.peekHeight)
        .onAppear {
            animateTo(isPeeking ? 1 : 0)
        }
        .onChange(of: isPeeking) { _, peeking in
            animateTo(peeking ? 1 : 0)
        }
    }

    private func animateTo(_ target: CGFloat) {
        withAnimation(
            target > 0
                ? .spring(response: 0.30, dampingFraction: 0.72)
                : .spring(response: 0.22, dampingFraction: 0.88)
        ) {
            visibility = target
        }
    }
}

#Preview {
    PeekView(isPeeking: true)
        .frame(width: PeekWindow.peekWidth, height: PeekWindow.peekHeight)
        .background(Color.gray.opacity(0.2))
}
