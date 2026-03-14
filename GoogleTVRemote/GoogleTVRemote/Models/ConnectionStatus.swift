import Foundation

enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected(runningApp: String?)
    case error(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}
