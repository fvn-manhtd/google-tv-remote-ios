import SwiftUI

struct DPadView: View {
    let onDirection: (DPadDirection) -> Void
    let onSelect: () -> Void
    var onLongPressStart: ((DPadDirection) -> Void)?
    var onLongPressEnd: ((DPadDirection) -> Void)?

    private let outerSize: CGFloat = 220
    private let centerSize: CGFloat = 70
    private let buttonSize: CGFloat = 50

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: outerSize, height: outerSize)

            // Up
            RemoteButton(icon: "chevron.up", label: "Up", action: { onDirection(.up) },
                         longPressStart: onLongPressStart.map { closure in { closure(.up) } },
                         longPressEnd: onLongPressEnd.map { closure in { closure(.up) } },
                         size: buttonSize)
            .offset(y: -70)

            // Down
            RemoteButton(icon: "chevron.down", label: "Down", action: { onDirection(.down) },
                         longPressStart: onLongPressStart.map { closure in { closure(.down) } },
                         longPressEnd: onLongPressEnd.map { closure in { closure(.down) } },
                         size: buttonSize)
            .offset(y: 70)

            // Left
            RemoteButton(icon: "chevron.left", label: "Left", action: { onDirection(.left) },
                         longPressStart: onLongPressStart.map { closure in { closure(.left) } },
                         longPressEnd: onLongPressEnd.map { closure in { closure(.left) } },
                         size: buttonSize)
            .offset(x: -70)

            // Right
            RemoteButton(icon: "chevron.right", label: "Right", action: { onDirection(.right) },
                         longPressStart: onLongPressStart.map { closure in { closure(.right) } },
                         longPressEnd: onLongPressEnd.map { closure in { closure(.right) } },
                         size: buttonSize)
            .offset(x: 70)

            // Center OK
            Button(action: {
                HapticManager.shared.medium()
                onSelect()
            }) {
                Text("OK")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: centerSize, height: centerSize)
                    .background(Circle().fill(Color.accentColor.opacity(0.2)))
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel("Select")
        }
        .frame(width: outerSize, height: outerSize)
    }
}
