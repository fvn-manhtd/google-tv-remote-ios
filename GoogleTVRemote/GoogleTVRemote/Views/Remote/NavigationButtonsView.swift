import SwiftUI

struct NavigationButtonsView: View {
    let onBack: () -> Void
    let onHome: () -> Void
    let onMenu: () -> Void

    var body: some View {
        HStack(spacing: 40) {
            RemoteButton(icon: "arrow.uturn.backward", label: "Back", action: onBack)
            RemoteButton(icon: "house", label: "Home", action: onHome, size: 52, fontSize: 24)
            RemoteButton(icon: "line.3.horizontal", label: "Menu", action: onMenu)
        }
    }
}
