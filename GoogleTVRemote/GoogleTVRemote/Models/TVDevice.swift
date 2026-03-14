import Foundation

enum ResolutionStatus: Codable, Hashable {
    case unresolved
    case resolving
    case resolved
    case failed
}

struct TVDevice: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var host: String
    var port: UInt16?
    var macAddress: String?
    var isPaired: Bool
    var lastConnected: Date?

    var bonjourName: String?
    var bonjourType: String?
    var bonjourDomain: String?
    var resolutionStatus: ResolutionStatus

    init(name: String, host: String, port: UInt16? = nil, macAddress: String? = nil,
         isPaired: Bool = false, bonjourName: String? = nil,
         bonjourType: String? = nil, bonjourDomain: String? = nil) {
        self.id = UUID()
        self.name = name
        self.host = host
        self.port = port
        self.macAddress = macAddress
        self.isPaired = isPaired
        self.bonjourName = bonjourName
        self.bonjourType = bonjourType
        self.bonjourDomain = bonjourDomain
        self.resolutionStatus = host.isEmpty ? .unresolved : .resolved
    }

    // Custom decoder for backwards compatibility with saved devices
    // that don't have the new `port` or `resolutionStatus` fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        host = try container.decode(String.self, forKey: .host)
        port = try container.decodeIfPresent(UInt16.self, forKey: .port)
        macAddress = try container.decodeIfPresent(String.self, forKey: .macAddress)
        isPaired = try container.decode(Bool.self, forKey: .isPaired)
        lastConnected = try container.decodeIfPresent(Date.self, forKey: .lastConnected)
        bonjourName = try container.decodeIfPresent(String.self, forKey: .bonjourName)
        bonjourType = try container.decodeIfPresent(String.self, forKey: .bonjourType)
        bonjourDomain = try container.decodeIfPresent(String.self, forKey: .bonjourDomain)
        resolutionStatus = try container.decodeIfPresent(ResolutionStatus.self, forKey: .resolutionStatus)
            ?? (host.isEmpty ? .unresolved : .resolved)
    }
}

extension TVDevice {
    static let storageKey = "paired_tvs"

    static func loadAll() -> [TVDevice] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let devices = try? JSONDecoder().decode([TVDevice].self, from: data)
        else { return [] }
        return devices
    }

    static func saveAll(_ devices: [TVDevice]) {
        if let data = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
