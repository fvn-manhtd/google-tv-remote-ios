import SwiftUI

struct TouchpadView: View {
    let onSwipe: (DPadDirection) -> Void
    let onTap: () -> Void

    private let swipeThreshold: CGFloat = 30

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.1))
            .frame(height: 200)
            .overlay(
                Text("Swipe to navigate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            )
            .accessibilityLabel("Touchpad. Swipe to navigate, tap to select")
            .gesture(
                DragGesture(minimumDistance: swipeThreshold)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height

                        HapticManager.shared.light()

                        if abs(horizontal) > abs(vertical) {
                            onSwipe(horizontal > 0 ? .right : .left)
                        } else {
                            onSwipe(vertical > 0 ? .down : .up)
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        HapticManager.shared.medium()
                        onTap()
                    }
            )
    }
}
