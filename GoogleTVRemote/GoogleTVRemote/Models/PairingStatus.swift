import Foundation

enum PairingStatus: Equatable {
    case idle
    case connecting
    case waitingForCode
    case validating
    case success
    case failed(String)
}
