import XCTest
@testable import GoogleTVRemote

final class CertificateGeneratorTests: XCTestCase {

    func testGenerateCertificate() throws {
        let result = try CertificateGenerator.generate(commonName: "TestDevice")

        XCTAssertFalse(result.certDER.isEmpty, "Certificate DER data should not be empty")
        XCTAssertFalse(result.privateKeyData.isEmpty, "Private key data should not be empty")
    }

    func testCertificateIsValidDER() throws {
        let result = try CertificateGenerator.generate()

        // Should start with ASN.1 SEQUENCE tag (0x30)
        XCTAssertEqual(result.certDER[0], 0x30, "Certificate should start with SEQUENCE tag")

        // SecCertificateCreateWithData should accept it
        let certRef = SecCertificateCreateWithData(nil, result.certDER as CFData)
        XCTAssertNotNil(certRef, "Certificate DER should be parseable by Security framework")
    }

    func testPrivateKeyIsRestorable() throws {
        let result = try CertificateGenerator.generate()

        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]
        var error: Unmanaged<CFError>?
        let key = SecKeyCreateWithData(result.privateKeyData as CFData, keyAttributes as CFDictionary, &error)
        XCTAssertNotNil(key, "Private key should be restorable from external representation")
    }

    func testASN1SequenceEncoding() {
        let content = Data([0x01, 0x02, 0x03])
        let encoded = ASN1.sequence(content)

        XCTAssertEqual(encoded[0], 0x30, "First byte should be SEQUENCE tag")
        XCTAssertEqual(encoded[1], 3, "Length should be 3")
        XCTAssertEqual(encoded.dropFirst(2), content)
    }

    func testASN1IntegerEncoding() {
        let value = Data([0x42])
        let encoded = ASN1.integer(value)

        XCTAssertEqual(encoded[0], 0x02, "First byte should be INTEGER tag")
        XCTAssertEqual(encoded[1], 1, "Length should be 1")
        XCTAssertEqual(encoded[2], 0x42)
    }
}
