import Foundation
import Network

class WakeOnLANService {

    static func buildMagicPacket(macAddress: String) -> Data? {
        let cleaned = macAddress
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
            .uppercased()

        guard cleaned.count == 12 else { return nil }

        var macBytes: [UInt8] = []
        var index = cleaned.startIndex
        for _ in 0..<6 {
            let nextIndex = cleaned.index(index, offsetBy: 2)
            guard let byte = UInt8(cleaned[index..<nextIndex], radix: 16) else { return nil }
            macBytes.append(byte)
            index = nextIndex
        }

        var packet = Data(repeating: 0xFF, count: 6)
        for _ in 0..<16 {
            packet.append(contentsOf: macBytes)
        }

        assert(packet.count == 102)
        return packet
    }

    func wake(
        macAddress: String,
        broadcastAddress: String = "255.255.255.255",
        completion: @escaping (Bool) -> Void
    ) {
        guard let packet = Self.buildMagicPacket(macAddress: macAddress) else {
            completion(false)
            return
        }

        let port = NWEndpoint.Port(rawValue: Constants.Ports.wol)!
        let host = NWEndpoint.Host(broadcastAddress)

        var sendCount = 0

        func sendPacket() {
            guard sendCount < Constants.Connection.wolRetryCount else {
                completion(true)
                return
            }

            let connection = NWConnection(host: host, port: port, using: .udp)
            connection.start(queue: .global(qos: .userInitiated))

            connection.send(content: packet, completion: .contentProcessed { _ in
                connection.cancel()
                sendCount += 1

                if sendCount < Constants.Connection.wolRetryCount {
                    DispatchQueue.global().asyncAfter(
                        deadline: .now() + Constants.Connection.wolRetryInterval
                    ) {
                        sendPacket()
                    }
                } else {
                    completion(true)
                }
            })
        }

        sendPacket()
    }

    func pollForConnection(
        host: String,
        port: UInt16 = Constants.Ports.remote,
        completion: @escaping (Bool) -> Void
    ) {
        let startTime = Date()
        let timeout = Constants.Connection.wolPollTimeout
        let interval = Constants.Connection.wolPollInterval

        func attempt() {
            guard Date().timeIntervalSince(startTime) < timeout else {
                completion(false)
                return
            }

            let endpoint = NWEndpoint.hostPort(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(rawValue: port)!
            )
            let connection = NWConnection(to: endpoint, using: .tcp)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.cancel()
                    DispatchQueue.main.async { completion(true) }
                case .failed, .cancelled:
                    DispatchQueue.global().asyncAfter(deadline: .now() + interval) {
                        attempt()
                    }
                default:
                    break
                }
            }

            connection.start(queue: .global(qos: .userInitiated))

            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                if connection.state != .ready {
                    connection.cancel()
                }
            }
        }

        attempt()
    }
}
