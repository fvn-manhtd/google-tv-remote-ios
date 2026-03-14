import XCTest
@testable import GoogleTVRemote

final class WakeOnLANServiceTests: XCTestCase {

    func testBuildMagicPacketValidMAC() {
        let mac = "AA:BB:CC:DD:EE:FF"
        let packet = WakeOnLANService.buildMagicPacket(macAddress: mac)

        XCTAssertNotNil(packet, "Packet should not be nil for valid MAC")
        XCTAssertEqual(packet?.count, 102, "Magic packet must be exactly 102 bytes")

        // First 6 bytes should be 0xFF
        if let packet = packet {
            for i in 0..<6 {
                XCTAssertEqual(packet[i], 0xFF, "Byte \(i) should be 0xFF")
            }

            // Next 96 bytes should be MAC repeated 16 times
            let macBytes: [UInt8] = [0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]
            for rep in 0..<16 {
                for b in 0..<6 {
                    let idx = 6 + (rep * 6) + b
                    XCTAssertEqual(packet[idx], macBytes[b],
                                   "Byte at \(idx) should be \(macBytes[b])")
                }
            }
        }
    }

    func testBuildMagicPacketWithDashes() {
        let mac = "AA-BB-CC-DD-EE-FF"
        let packet = WakeOnLANService.buildMagicPacket(macAddress: mac)
        XCTAssertNotNil(packet)
        XCTAssertEqual(packet?.count, 102)
    }

    func testBuildMagicPacketWithoutSeparators() {
        let mac = "AABBCCDDEEFF"
        let packet = WakeOnLANService.buildMagicPacket(macAddress: mac)
        XCTAssertNotNil(packet)
        XCTAssertEqual(packet?.count, 102)
    }

    func testBuildMagicPacketInvalidMAC() {
        XCTAssertNil(WakeOnLANService.buildMagicPacket(macAddress: ""))
        XCTAssertNil(WakeOnLANService.buildMagicPacket(macAddress: "AA:BB:CC"))
        XCTAssertNil(WakeOnLANService.buildMagicPacket(macAddress: "GGHHIIJJKKLL"))
        XCTAssertNil(WakeOnLANService.buildMagicPacket(macAddress: "AA:BB:CC:DD:EE:GG"))
    }

    func testBuildMagicPacketLowercaseMAC() {
        let mac = "aa:bb:cc:dd:ee:ff"
        let packet = WakeOnLANService.buildMagicPacket(macAddress: mac)
        XCTAssertNotNil(packet)
        XCTAssertEqual(packet?.count, 102)
    }
}
