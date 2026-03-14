import Foundation
import Combine

@MainActor
class DiscoveryViewModel: ObservableObject {
    @Published var devices: [TVDevice] = []
    @Published var isScanning = false

    private let discoveryService = TVDiscoveryService()
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?

    init() {
        discoveryService.$discoveredDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] discovered in
                self?.mergeDevices(discovered: discovered)
            }
            .store(in: &cancellables)

        discoveryService.$isScanning
            .receive(on: DispatchQueue.main)
            .assign(to: &$isScanning)

        // Load saved paired devices initially
        devices = TVDevice.loadAll()
    }

    func startScan() {
        discoveryService.startScan()
        startPeriodicRefresh()
    }

    func stopScan() {
        discoveryService.stopScan()
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refresh() {
        discoveryService.stopScan()
        discoveryService.startScan()
    }

    func addManualDevice(host: String) -> TVDevice {
        return discoveryService.addManualDevice(host: host)
    }

    func resolveDevice(_ device: TVDevice, completion: @escaping (String?) -> Void) {
        discoveryService.resolveDevice(device, completion: completion)
    }

    private func mergeDevices(discovered: [TVDevice]) {
        let saved = TVDevice.loadAll()
        var merged: [TVDevice] = []

        // Start with discovered devices, updating with saved info
        for var disc in discovered {
            if let saved = saved.first(where: { $0.name == disc.name || $0.bonjourName == disc.bonjourName }) {
                disc.isPaired = saved.isPaired
                disc.lastConnected = saved.lastConnected
                if disc.host.isEmpty { disc.host = saved.host }
                if disc.macAddress == nil { disc.macAddress = saved.macAddress }
            }
            merged.append(disc)
        }

        // Add saved paired devices that weren't discovered (offline TVs)
        for saved in saved where saved.isPaired {
            if !merged.contains(where: { $0.name == saved.name || $0.bonjourName == saved.bonjourName }) {
                merged.append(saved)
            }
        }

        devices = merged
    }

    private func startPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Constants.Discovery.scanInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }
}
