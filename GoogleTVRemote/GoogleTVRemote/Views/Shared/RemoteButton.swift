import SwiftUI

struct RemoteButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var longPressStart: (() -> Void)?
    var longPressEnd: (() -> Void)?
    var size: CGFloat = 44
    var fontSize: CGFloat = 20

    @State private var isPressed = false
    @State private var isLongPressing = false
    @State private var longPressTimer: Timer?

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: fontSize, weight: .medium))
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15))
            )
            .foregroundStyle(.primary)
            .accessibilityLabel(label)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            HapticManager.shared.light()

                            if longPressStart != nil {
                                longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                    Task { @MainActor in
                                        isLongPressing = true
                                        longPressStart?()
                                    }
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        longPressTimer?.invalidate()
                        longPressTimer = nil

                        if isLongPressing {
                            isLongPressing = false
                            longPressEnd?()
                        } else {
                            action()
                        }
                    }
            )
    }
}
