import Foundation
import AndroidTVRemoteControl

enum DPadDirection {
    case up, down, left, right
}

@MainActor
class TVRemoteService: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .disconnected

    private var remoteManager: RemoteManager?
    private let keychainService: KeychainService
    private let queue = DispatchQueue(label: "com.googletv-remote.remote")
    private var reconnectAttempts = 0
    private var currentHost: String?

    init(keychainService: KeychainService = KeychainService()) {
        self.keychainService = keychainService
    }

    func connect(host: String) {
        currentHost = host
        connectionStatus = .connecting
        reconnectAttempts = 0

        do {
            guard let stored = try keychainService.loadCertificate() else {
                connectionStatus = .error("No pairing certificate found. Please re-pair.")
                return
            }

            // Write DER cert to temp file
            let certURL = FileManager.default.temporaryDirectory.appendingPathComponent("client_cert.der")
            try stored.certDER.write(to: certURL)

            // Create identity for TLS
            let (identity, certRef) = try CertificateGenerator.createIdentity(
                certDER: stored.certDER,
                privateKeyData: stored.privateKey
            )

            let cryptoManager = CryptoManager()
            cryptoManager.clientPublicCertificate = {
                return CertManager().getSecKey(certURL)
            }

            let tlsManager = TLSManager {
                let identityDict: [String: Any] = [
                    kSecImportItemIdentity as String: identity,
                    kSecImportItemCertChain as String: [certRef] as CFArray
                ]
                return .Result([identityDict] as CFArray)
            }

            tlsManager.secTrustClosure = { secTrust in
                cryptoManager.serverPublicCertificate = {
                    if let key = SecTrustCopyKey(secTrust) {
                        return .Result(key)
                    }
                    return .Error(.secTrustCopyKeyError)
                }
            }

            let deviceInfo = CommandNetwork.DeviceInfo(
                Constants.DeviceInfo.model,
                Constants.DeviceInfo.vendor,
                Constants.DeviceInfo.version,
                Constants.DeviceInfo.appName,
                Constants.DeviceInfo.appBuild
            )

            remoteManager = RemoteManager(tlsManager, deviceInfo)

            remoteManager?.stateChanged = { [weak self] state in
                Task { @MainActor in
                    self?.handleRemoteState(state)
                }
            }

            remoteManager?.connect(host)

        } catch {
            connectionStatus = .error(error.localizedDescription)
        }
    }

    // MARK: - Key Commands

    func sendKey(_ key: Key, direction: Direction = .SHORT) {
        remoteManager?.send(KeyPress(key, direction))
    }

    func sendDeepLink(_ url: String) {
        remoteManager?.send(DeepLink(url))
    }

    func sendDPad(_ direction: DPadDirection) {
        switch direction {
        case .up:    sendKey(.KEYCODE_DPAD_UP)
        case .down:  sendKey(.KEYCODE_DPAD_DOWN)
        case .left:  sendKey(.KEYCODE_DPAD_LEFT)
        case .right: sendKey(.KEYCODE_DPAD_RIGHT)
        }
    }

    func sendSelect()      { sendKey(.KEYCODE_DPAD_CENTER) }
    func sendHome()        { sendKey(.KEYCODE_HOME) }
    func sendBack()        { sendKey(.KEYCODE_BACK) }
    func sendMenu()        { sendKey(.KEYCODE_MENU) }
    func sendPower()       { sendKey(.KEYCODE_POWER) }
    func sendVolumeUp()    { sendKey(.KEYCODE_VOLUME_UP) }
    func sendVolumeDown()  { sendKey(.KEYCODE_VOLUME_DOWN) }
    func sendMute()        { sendKey(.KEYCODE_MUTE) }
    func sendPlayPause()   { sendKey(.KEYCODE_MEDIA_PLAY_PAUSE) }
    func sendStop()        { sendKey(.KEYCODE_MEDIA_STOP) }
    func sendNext()        { sendKey(.KEYCODE_MEDIA_NEXT) }
    func sendPrevious()    { sendKey(.KEYCODE_MEDIA_PREVIOUS) }
    func sendRewind()      { sendKey(.KEYCODE_MEDIA_REWIND) }
    func sendFastForward() { sendKey(.KEYCODE_MEDIA_FAST_FORWARD) }

    func startLongPress(_ key: Key) { sendKey(key, direction: .START_LONG) }
    func endLongPress(_ key: Key)   { sendKey(key, direction: .END_LONG) }

    // MARK: - State Handling

    private func handleRemoteState(_ state: RemoteManager.RemoteState) {
        switch state {
        case .idle:
            connectionStatus = .disconnected
        case .paired(let runningApp):
            connectionStatus = .connected(runningApp: runningApp)
            reconnectAttempts = 0
        case .error(let err):
            connectionStatus = .error("\(err)")
            attemptReconnect()
        default:
            connectionStatus = .connecting
        }
    }

    private func attemptReconnect() {
        guard reconnectAttempts < Constants.Connection.reconnectMaxRetries,
              let host = currentHost else {
            connectionStatus = .error("Connection lost. Please reconnect manually.")
            return
        }

        reconnectAttempts += 1
        let delay = Constants.Connection.reconnectInterval * Double(reconnectAttempts)

        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            connect(host: host)
        }
    }

    func disconnect() {
        remoteManager?.disconnect()
        remoteManager = nil
        connectionStatus = .disconnected
        currentHost = nil
    }
}
