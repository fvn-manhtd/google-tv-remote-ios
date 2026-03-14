import Foundation
import Network
import Combine

@MainActor
class TVDiscoveryService: ObservableObject {
    @Published var discoveredDevices: [TVDevice] = []
    @Published var isScanning = false

    private var browser: NWBrowser?
    private let queue = DispatchQueue(label: "com.googletv-remote.discovery", qos: .userInitiated)

    /// Active resolution connections keyed by Bonjour name
    private var activeResolutions: [String: NWConnection] = [:]

    // MARK: - Scanning

    func startScan() {
        stopScan()

        let params = NWParameters()
        params.includePeerToPeer = true

        browser = NWBrowser(
            for: .bonjourWithTXTRecord(type: Constants.Discovery.bonjourType, domain: nil),
            using: params
        )

        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            Task { @MainActor in
                self?.handleBrowseResults(results, changes: changes)
            }
        }

        browser?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.isScanning = true
                case .failed(let error):
                    print("[Discovery] Browser failed: \(error)")
                    self?.isScanning = false
                case .cancelled:
                    self?.isScanning = false
                default:
                    break
                }
            }
        }

        browser?.start(queue: queue)
    }

    func stopScan() {
        browser?.cancel()
        browser = nil
        isScanning = false
        cancelAllResolutions()
    }

    // MARK: - Browse Result Processing

    private func handleBrowseResults(_ results: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>) {
        let savedDevices = TVDevice.loadAll()

        // Process additions and changes — resolve new devices via mDNS
        for change in changes {
            switch change {
            case .added(let result):
                if let device = makeDevice(from: result, savedDevices: savedDevices) {
                    addOrUpdateDevice(device)
                    if device.host.isEmpty {
                        resolveEndpoint(result.endpoint, for: device)
                    }
                }

            case .removed(let result):
                if case .service(let name, _, _, _) = result.endpoint {
                    cancelResolution(for: name)
                    discoveredDevices.removeAll { $0.bonjourName == name }
                }

            case .changed(old: _, new: let result, flags: _):
                if let device = makeDevice(from: result, savedDevices: savedDevices) {
                    addOrUpdateDevice(device)
                    // Re-resolve if host is still empty
                    if device.host.isEmpty {
                        resolveEndpoint(result.endpoint, for: device)
                    }
                }

            default:
                break
            }
        }

        // On first callback, changes may be empty — process all results
        if changes.isEmpty {
            processAllResults(results, savedDevices: savedDevices)
        }
    }

    private func processAllResults(_ results: Set<NWBrowser.Result>, savedDevices: [TVDevice]) {
        for result in results {
            guard let device = makeDevice(from: result, savedDevices: savedDevices) else { continue }
            addOrUpdateDevice(device)
            if device.host.isEmpty {
                resolveEndpoint(result.endpoint, for: device)
            }
        }
    }

    private func makeDevice(from result: NWBrowser.Result, savedDevices: [TVDevice]) -> TVDevice? {
        guard case .service(let name, _, _, _) = result.endpoint else { return nil }

        var macAddress: String?
        if case .bonjour(let txtRecord) = result.metadata {
            macAddress = Self.extractTXTValue(txtRecord, key: "bt")
                ?? Self.extractTXTValue(txtRecord, key: "mac")
        }

        // Merge with saved device data if available
        if let saved = savedDevices.first(where: { $0.name == name || $0.bonjourName == name }) {
            var device = saved
            device.macAddress = macAddress ?? saved.macAddress
            device.bonjourName = name
            return device
        }

        return TVDevice(
            name: name,
            host: "",
            macAddress: macAddress,
            bonjourName: name
        )
    }

    private func addOrUpdateDevice(_ device: TVDevice) {
        if let index = discoveredDevices.firstIndex(where: {
            $0.bonjourName == device.bonjourName || $0.name == device.name
        }) {
            // Preserve resolved host if already resolved
            var updated = device
            if updated.host.isEmpty && !discoveredDevices[index].host.isEmpty {
                updated.host = discoveredDevices[index].host
                updated.port = discoveredDevices[index].port
                updated.resolutionStatus = discoveredDevices[index].resolutionStatus
            }
            discoveredDevices[index] = updated
        } else {
            discoveredDevices.append(device)
        }
    }

    // MARK: - mDNS Resolution

    /// Resolves a Bonjour service endpoint to an IP address using NWConnection's path resolution.
    /// Uses UDP to avoid needing a full TCP handshake — we only need DNS resolution, not a connection.
    private func resolveEndpoint(_ endpoint: NWEndpoint, for device: TVDevice) {
        guard case .service(let name, _, _, _) = endpoint else { return }

        // Cancel any existing resolution for this name
        cancelResolution(for: name)

        // Mark as resolving
        updateDeviceResolutionStatus(name: name, status: .resolving)

        // Use UDP instead of TCP — avoids TCP handshake failures when the TV
        // doesn't accept raw TCP connections on the service port.
        // We only need the path to resolve the mDNS name to an IP.
        let connection = NWConnection(to: endpoint, using: .udp)
        activeResolutions[name] = connection

        // Use pathUpdateHandler to get the resolved address without needing
        // a full connection. The path resolves the Bonjour name via mDNS.
        connection.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                // Check if we already resolved (avoid duplicate processing)
                guard self.activeResolutions[name] != nil else { return }

                if let remoteEndpoint = path.remoteEndpoint,
                   case .hostPort(let host, let port) = remoteEndpoint {
                    let hostString = self.hostToString(host)
                    let portValue = UInt16(port.rawValue)

                    if let index = self.discoveredDevices.firstIndex(where: { $0.bonjourName == name }) {
                        self.discoveredDevices[index].host = hostString
                        self.discoveredDevices[index].port = portValue
                        self.discoveredDevices[index].resolutionStatus = .resolved
                        print("[Discovery] Resolved \(name) → \(hostString):\(portValue)")
                    }

                    connection.cancel()
                    self.activeResolutions.removeValue(forKey: name)
                }
            }
        }

        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .ready:
                    // Also try to extract from the connection path when ready
                    if let path = connection.currentPath,
                       let remoteEndpoint = path.remoteEndpoint,
                       case .hostPort(let host, let port) = remoteEndpoint,
                       self.activeResolutions[name] != nil {
                        let hostString = self.hostToString(host)
                        let portValue = UInt16(port.rawValue)

                        if let index = self.discoveredDevices.firstIndex(where: { $0.bonjourName == name }) {
                            self.discoveredDevices[index].host = hostString
                            self.discoveredDevices[index].port = portValue
                            self.discoveredDevices[index].resolutionStatus = .resolved
                            print("[Discovery] Resolved (ready) \(name) → \(hostString):\(portValue)")
                        }

                        connection.cancel()
                        self.activeResolutions.removeValue(forKey: name)
                    }

                case .failed:
                    // UDP "failure" is expected — we only care about path resolution
                    // If we haven't resolved yet, mark as failed
                    if self.activeResolutions[name] != nil {
                        self.updateDeviceResolutionStatus(name: name, status: .failed)
                        self.activeResolutions.removeValue(forKey: name)
                    }

                case .cancelled:
                    self.activeResolutions.removeValue(forKey: name)

                default:
                    break
                }
            }
        }

        connection.start(queue: queue)

        // Timeout
        queue.asyncAfter(deadline: .now() + Constants.Discovery.resolutionTimeout) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if self.activeResolutions[name] != nil {
                    print("[Discovery] Resolution timed out for \(name)")
                    connection.cancel()
                    self.activeResolutions.removeValue(forKey: name)
                    self.updateDeviceResolutionStatus(name: name, status: .failed)
                }
            }
        }
    }

    private func hostToString(_ host: NWEndpoint.Host) -> String {
        switch host {
        case .ipv4(let addr):
            return "\(addr)"
        case .ipv6(let addr):
            return "\(addr)"
        default:
            return "\(host)"
        }
    }

    /// Resolve a specific device on-demand (used when tapping an unresolved device)
    func resolveDevice(_ device: TVDevice, completion: @escaping (String?) -> Void) {
        // If already resolved, return immediately
        if !device.host.isEmpty {
            completion(device.host)
            return
        }

        guard let bonjourName = device.bonjourName else {
            completion(nil)
            return
        }

        let endpoint = NWEndpoint.service(
            name: bonjourName,
            type: Constants.Discovery.bonjourType,
            domain: "local.",
            interface: nil
        )

        var completed = false
        let connection = NWConnection(to: endpoint, using: .udp)

        connection.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard !completed else { return }
                if let remoteEndpoint = path.remoteEndpoint,
                   case .hostPort(let host, _) = remoteEndpoint {
                    completed = true
                    let hostString = self?.hostToString(host) ?? "\(host)"
                    connection.cancel()

                    if let index = self?.discoveredDevices.firstIndex(where: { $0.bonjourName == bonjourName }) {
                        self?.discoveredDevices[index].host = hostString
                        self?.discoveredDevices[index].resolutionStatus = .resolved
                    }

                    completion(hostString)
                }
            }
        }

        connection.stateUpdateHandler = { state in
            Task { @MainActor in
                guard !completed else { return }
                if case .failed = state {
                    completed = true
                    connection.cancel()
                    completion(nil)
                }
            }
        }

        connection.start(queue: queue)

        queue.asyncAfter(deadline: .now() + Constants.Discovery.resolutionTimeout) {
            Task { @MainActor in
                guard !completed else { return }
                completed = true
                connection.cancel()
                completion(nil)
            }
        }
    }

    // MARK: - Resolution Lifecycle

    private func updateDeviceResolutionStatus(name: String, status: ResolutionStatus) {
        if let index = discoveredDevices.firstIndex(where: { $0.bonjourName == name }) {
            discoveredDevices[index].resolutionStatus = status
        }
    }

    private func cancelResolution(for name: String) {
        activeResolutions[name]?.cancel()
        activeResolutions.removeValue(forKey: name)
    }

    private func cancelAllResolutions() {
        for (_, connection) in activeResolutions {
            connection.cancel()
        }
        activeResolutions.removeAll()
    }

    // MARK: - TXT Record Parsing

    private static func extractTXTValue(_ txtRecord: NWTXTRecord, key: String) -> String? {
        guard let entry = txtRecord.getEntry(for: key) else { return nil }
        if case let .string(value) = entry {
            return value
        }
        return nil
    }

    // MARK: - Manual Device

    func addManualDevice(host: String, name: String = "Google TV") -> TVDevice {
        let device = TVDevice(name: name, host: host)
        if !discoveredDevices.contains(where: { $0.host == host }) {
            discoveredDevices.append(device)
        }
        return device
    }
}
