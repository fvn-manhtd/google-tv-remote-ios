import XCTest
@testable import GoogleTVRemote

final class KeychainServiceTests: XCTestCase {

    private var service: KeychainService!
    private let testAccount = "test_keychain_account"

    override func setUp() {
        super.setUp()
        service = KeychainService()
        try? service.deleteData(for: testAccount)
    }

    override func tearDown() {
        try? service.deleteData(for: testAccount)
        super.tearDown()
    }

    func testSaveAndLoadData() throws {
        let testData = "Hello, Keychain!".data(using: .utf8)!

        try service.saveData(testData, for: testAccount)
        let loaded = try service.loadData(for: testAccount)

        XCTAssertEqual(loaded, testData, "Loaded data should match saved data")
    }

    func testLoadNonExistentReturnsNil() throws {
        let loaded = try service.loadData(for: "nonexistent_account_xyz")
        XCTAssertNil(loaded, "Loading non-existent account should return nil")
    }

    func testDeleteData() throws {
        let testData = Data([0x01, 0x02, 0x03])
        try service.saveData(testData, for: testAccount)

        try service.deleteData(for: testAccount)
        let loaded = try service.loadData(for: testAccount)

        XCTAssertNil(loaded, "Data should be nil after deletion")
    }

    func testHasData() throws {
        XCTAssertFalse(service.hasData(for: testAccount))

        try service.saveData(Data([0xFF]), for: testAccount)
        XCTAssertTrue(service.hasData(for: testAccount))
    }

    func testOverwriteExistingData() throws {
        let data1 = "first".data(using: .utf8)!
        let data2 = "second".data(using: .utf8)!

        try service.saveData(data1, for: testAccount)
        try service.saveData(data2, for: testAccount)

        let loaded = try service.loadData(for: testAccount)
        XCTAssertEqual(loaded, data2, "Should return the most recently saved data")
    }
}
