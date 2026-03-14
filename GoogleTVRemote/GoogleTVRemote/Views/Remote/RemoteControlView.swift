import SwiftUI
import AndroidTVRemoteControl

struct RemoteControlView: View {
    @StateObject var viewModel: RemoteViewModel
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var showKeyboard = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ConnectionStatusBanner(status: viewModel.connectionStatus)

                if sizeClass == .regular {
                    HStack(alignment: .top, spacing: 32) {
                        controlsColumn
                        touchpadAndMedia
                    }
                    .padding()
                    .frame(maxHeight: .infinity, alignment: .top)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            topActionRow
                            dpadSection
                            navigationRow
                            volumeRow
                            mediaRow
                            TouchpadView(
                                onSwipe: { viewModel.sendDPad($0) },
                                onTap: { viewModel.sendSelect() }
                            )
                        }
                        .padding()
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .navigationTitle(viewModel.deviceName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showKeyboard = true }) {
                    Image(systemName: "keyboard")
                }
            }
        }
        .sheet(isPresented: $showKeyboard) {
            KeyboardInputView(remoteService: viewModel.remoteService)
        }
    }

    // MARK: - Top Action Row
    private var topActionRow: some View {
        HStack(spacing: 24) {
            RemoteButton(icon: "power", label: "Power", action: viewModel.togglePower)
            RemoteButton(icon: "rectangle.on.rectangle", label: "Input",
                        action: { viewModel.sendKey(.KEYCODE_SETTINGS) })
            RemoteButton(icon: "speaker.slash", label: "Mute", action: viewModel.sendMute)
            RemoteButton(icon: "airplayvideo", label: "Cast",
                        action: viewModel.openScreenMirror)
        }
    }

    // MARK: - D-Pad
    private var dpadSection: some View {
        DPadView(
            onDirection: { viewModel.sendDPad($0) },
            onSelect: { viewModel.sendSelect() },
            onLongPressStart: { dir in
                let key: Key = {
                    switch dir {
                    case .up: return .KEYCODE_DPAD_UP
                    case .down: return .KEYCODE_DPAD_DOWN
                    case .left: return .KEYCODE_DPAD_LEFT
                    case .right: return .KEYCODE_DPAD_RIGHT
                    }
                }()
                viewModel.startLongPress(key)
            },
            onLongPressEnd: { dir in
                let key: Key = {
                    switch dir {
                    case .up: return .KEYCODE_DPAD_UP
                    case .down: return .KEYCODE_DPAD_DOWN
                    case .left: return .KEYCODE_DPAD_LEFT
                    case .right: return .KEYCODE_DPAD_RIGHT
                    }
                }()
                viewModel.endLongPress(key)
            }
        )
    }

    // MARK: - Navigation Row
    private var navigationRow: some View {
        NavigationButtonsView(
            onBack: viewModel.sendBack,
            onHome: viewModel.sendHome,
            onMenu: viewModel.sendMenu
        )
    }

    // MARK: - Volume Row
    private var volumeRow: some View {
        VolumeControlView(
            onVolumeUp: viewModel.sendVolumeUp,
            onVolumeDown: viewModel.sendVolumeDown
        )
    }

    // MARK: - Media Row
    private var mediaRow: some View {
        MediaControlsView(
            onRewind: viewModel.sendRewind,
            onPrevious: viewModel.sendPrevious,
            onPlayPause: viewModel.sendPlayPause,
            onNext: viewModel.sendNext,
            onFastForward: viewModel.sendFastForward
        )
    }

    // iPad columns
    private var controlsColumn: some View {
        VStack(spacing: 24) {
            topActionRow
            dpadSection
            navigationRow
            volumeRow
        }
        .frame(maxWidth: 300)
    }

    private var touchpadAndMedia: some View {
        VStack(spacing: 24) {
            TouchpadView(
                onSwipe: { viewModel.sendDPad($0) },
                onTap: { viewModel.sendSelect() }
            )
            mediaRow
        }
    }
}
