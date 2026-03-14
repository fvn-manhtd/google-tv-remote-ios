import Foundation

enum Constants {
    enum Ports {
        static let pairing: UInt16 = 6467
        static let remote: UInt16 = 6466
        static let wol: UInt16 = 9
    }

    enum Discovery {
        static let bonjourType = "_androidtvremote2._tcp"
        static let scanInterval: TimeInterval = 30
        static let resolutionTimeout: TimeInterval = 5
    }

    enum Connection {
        static let reconnectMaxRetries = 3
        static let reconnectInterval: TimeInterval = 2.0
        static let wolRetryCount = 3
        static let wolRetryInterval: TimeInterval = 1.0
        static let wolPollInterval: TimeInterval = 2.0
        static let wolPollTimeout: TimeInterval = 30.0
    }

    enum Keychain {
        static let service = "com.googletv-remote"
        static let clientCertDER = "client_cert_der"
        static let clientPrivateKey = "client_private_key"
    }

    enum DeviceInfo {
        static let model = "iPhone"
        static let vendor = "Apple"
        static let appName = "GoogleTVRemote"
        static let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let version = "1.0"
    }
}
