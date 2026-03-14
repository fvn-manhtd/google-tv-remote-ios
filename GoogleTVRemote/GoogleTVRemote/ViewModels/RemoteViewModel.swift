import Foundation
import UIKit
import AndroidTVRemoteControl
import Combine

@MainActor
class RemoteViewModel: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .disconnected

    let remoteService: TVRemoteService
    let deviceName: String
    private let device: TVDevice
    private let wolService = WakeOnLANService()
    private var cancellables = Set<AnyCancellable>()

    init(device: TVDevice) {
        self.device = device
        self.deviceName = device.name
        self.remoteService = TVRemoteService()

        remoteService.$connectionStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionStatus)

        // Save as last connected
        UserDefaults.standard.set(device.id.uuidString, forKey: "last_tv_id")

        // Update lastConnected timestamp
        updateLastConnected(device)

        if device.host.isEmpty, device.bonjourName != nil {
            let discoveryService = TVDiscoveryService()
            discoveryService.resolveDevice(device) { [weak self] resolvedHost in
                guard let self else { return }
                if let resolvedHost {
                    self.remoteService.connect(host: resolvedHost)
                } else {
                    self.connectionStatus = .error("Could not resolve device address. Try reconnecting.")
                }
            }
        } else {
            remoteService.connect(host: device.host)
        }
    }

    private func updateLastConnected(_ device: TVDevice) {
        var devices = TVDevice.loadAll()
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index].lastConnected = Date()
            TVDevice.saveAll(devices)
        }
    }

    // MARK: - D-Pad
    func sendDPad(_ direction: DPadDirection) {
        remoteService.sendDPad(direction)
    }

    func sendSelect()      { remoteService.sendSelect() }
    func sendHome()        { remoteService.sendHome() }
    func sendBack()        { remoteService.sendBack() }
    func sendMenu()        { remoteService.sendMenu() }
    func sendVolumeUp()    { remoteService.sendVolumeUp() }
    func sendVolumeDown()  { remoteService.sendVolumeDown() }
    func sendMute()        { remoteService.sendMute() }
    func sendPlayPause()   { remoteService.sendPlayPause() }
    func sendStop()        { remoteService.sendStop() }
    func sendNext()        { remoteService.sendNext() }
    func sendPrevious()    { remoteService.sendPrevious() }
    func sendRewind()      { remoteService.sendRewind() }
    func sendFastForward() { remoteService.sendFastForward() }

    func startLongPress(_ key: Key) { remoteService.startLongPress(key) }
    func endLongPress(_ key: Key)   { remoteService.endLongPress(key) }

    // MARK: - Power / WoL
    func togglePower() {
        if connectionStatus.isConnected {
            remoteService.sendPower()
        } else if let mac = device.macAddress {
            wolService.wake(macAddress: mac) { [weak self] sent in
                guard sent, let self else { return }
                self.wolService.pollForConnection(host: self.device.host) { reachable in
                    if reachable {
                        Task { @MainActor in
                            self.remoteService.connect(host: self.device.host)
                        }
                    }
                }
            }
        }
    }

    func sendKey(_ key: Key) {
        remoteService.sendKey(key)
    }

    // MARK: - Screen Mirror / Cast
    func openScreenMirror() {
        let googleHomeURL = URL(string: "googlehome://")!
        let appStoreURL = URL(string: "https://apps.apple.com/app/google-home/id680819774")!

        if UIApplication.shared.canOpenURL(googleHomeURL) {
            UIApplication.shared.open(googleHomeURL)
        } else {
            UIApplication.shared.open(appStoreURL)
        }
    }

    func disconnect() {
        remoteService.disconnect()
    }
}
