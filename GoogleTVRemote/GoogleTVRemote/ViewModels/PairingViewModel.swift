import Foundation
import Combine

@MainActor
class PairingViewModel: ObservableObject {
    @Published var status: PairingStatus = .idle
    @Published var pinCode: String = ""

    private let pairingService = TVPairingService()
    private var cancellables = Set<AnyCancellable>()
    private var device: TVDevice?

    init() {
        pairingService.$status
            .receive(on: DispatchQueue.main)
            .assign(to: &$status)
    }

    func startPairing(device: TVDevice) {
        self.device = device
        let host = device.host

        if host.isEmpty, let bonjourName = device.bonjourName {
            let discoveryService = TVDiscoveryService()
            discoveryService.resolveDevice(device) { [weak self] resolvedHost in
                guard let self, let resolvedHost else {
                    self?.status = .failed("Could not resolve device address.")
                    return
                }
                self.device?.host = resolvedHost
                self.pairingService.startPairing(host: resolvedHost)
            }
        } else {
            pairingService.startPairing(host: host)
        }
    }

    func submitPin() {
        pairingService.submitPin(pinCode)
    }

    @discardableResult
    func markDeviceAsPaired() -> TVDevice? {
        guard var device = self.device else { return nil }
        device.isPaired = true
        device.lastConnected = Date()

        var devices = TVDevice.loadAll()
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
        } else {
            devices.append(device)
        }
        TVDevice.saveAll(devices)
        self.device = device
        return device
    }

    func cancel() {
        pairingService.cancel()
    }
}
