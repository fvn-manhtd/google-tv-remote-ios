import XCTest
@testable import GoogleTVRemote

final class PINValidationTests: XCTestCase {

    private var pairingService: TVPairingService!

    @MainActor
    override func setUp() {
        super.setUp()
        pairingService = TVPairingService()
    }

    @MainActor
    func testValidPINs() {
        XCTAssertTrue(pairingService.validatePin("A1B2C3"))
        XCTAssertTrue(pairingService.validatePin("000000"))
        XCTAssertTrue(pairingService.validatePin("FFFFFF"))
        XCTAssertTrue(pairingService.validatePin("abcdef"))
        XCTAssertTrue(pairingService.validatePin("123456"))
        XCTAssertTrue(pairingService.validatePin("AbCdEf"))
    }

    @MainActor
    func testInvalidPINs() {
        // Too short
        XCTAssertFalse(pairingService.validatePin(""))
        XCTAssertFalse(pairingService.validatePin("A1B2C"))
        XCTAssertFalse(pairingService.validatePin("12345"))

        // Too long
        XCTAssertFalse(pairingService.validatePin("A1B2C3D"))
        XCTAssertFalse(pairingService.validatePin("1234567"))

        // Invalid characters
        XCTAssertFalse(pairingService.validatePin("GHIJKL"))
        XCTAssertFalse(pairingService.validatePin("A1B2G3"))
        XCTAssertFalse(pairingService.validatePin("12 456"))
        XCTAssertFalse(pairingService.validatePin("A1-2C3"))
    }
}
