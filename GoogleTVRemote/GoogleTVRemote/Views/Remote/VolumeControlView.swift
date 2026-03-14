import SwiftUI

struct VolumeControlView: View {
    let onVolumeUp: () -> Void
    let onVolumeDown: () -> Void

    var body: some View {
        HStack(spacing: 40) {
            RemoteButton(icon: "speaker.wave.1", label: "Volume Down", action: onVolumeDown)
            RemoteButton(icon: "speaker.wave.3", label: "Volume Up", action: onVolumeUp)
        }
    }
}
