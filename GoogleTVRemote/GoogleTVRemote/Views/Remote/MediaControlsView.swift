import SwiftUI

struct MediaControlsView: View {
    let onRewind: () -> Void
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onFastForward: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            RemoteButton(icon: "backward", label: "Rewind", action: onRewind, size: 40, fontSize: 16)
            RemoteButton(icon: "backward.end", label: "Previous", action: onPrevious, size: 40, fontSize: 16)
            RemoteButton(icon: "playpause", label: "Play Pause", action: onPlayPause, size: 52, fontSize: 24)
            RemoteButton(icon: "forward.end", label: "Next", action: onNext, size: 40, fontSize: 16)
            RemoteButton(icon: "forward", label: "Fast Forward", action: onFastForward, size: 40, fontSize: 16)
        }
    }
}
