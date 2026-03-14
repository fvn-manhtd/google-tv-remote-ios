import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var pairedDevices: [TVDevice] = []

    private let keychainService = KeychainService()

    init() {
        loadDevices()
    }

    func loadDevices() {
        pairedDevices = TVDevice.loadAll().filter { $0.isPaired }
    }

    func forgetDevice(_ device: TVDevice) {
        var devices = TVDevice.loadAll()
        devices.removeAll { $0.id == device.id }
        TVDevice.saveAll(devices)
        loadDevices()
    }

    func forgetAllDevices() {
        TVDevice.saveAll([])
        try? keychainService.deleteCertificate()
        CertificateGenerator.cleanupIdentity()
        loadDevices()
    }
}
