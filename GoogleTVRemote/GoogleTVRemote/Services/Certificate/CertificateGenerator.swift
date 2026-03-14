import Foundation
import Security

class CertificateGenerator {
    struct CertificateResult {
        let certDER: Data       // X.509 certificate in DER format
        let privateKeyData: Data // RSA private key (external representation)
    }

    static func generate(commonName: String = "GoogleTVRemote") throws -> CertificateResult {
        // Generate RSA 2048-bit key pair
        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: false
            ]
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(keyAttributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw NSError(domain: "CertGen", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract public key"])
        }

        let certDER = try buildSelfSignedCertificate(
            privateKey: privateKey,
            publicKey: publicKey,
            commonName: commonName
        )

        guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, nil) as Data? else {
            throw NSError(domain: "CertGen", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to export private key"])
        }

        return CertificateResult(certDER: certDER, privateKeyData: privateKeyData)
    }

    // MARK: - Build self-signed X.509 DER certificate

    private static func buildSelfSignedCertificate(
        privateKey: SecKey, publicKey: SecKey, commonName: String
    ) throws -> Data {
        let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil)! as Data

        var tbs = Data()
        tbs.append(ASN1.contextTag(0, value: ASN1.integer(Data([0x02]))))

        var serial = Data(count: 8)
        _ = serial.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 8, $0.baseAddress!) }
        serial[0] &= 0x7F
        tbs.append(ASN1.integer(serial))

        tbs.append(ASN1.sha256WithRSAAlgorithm())
        tbs.append(ASN1.rdnSequence(commonName: commonName))
        tbs.append(ASN1.validity(years: 10))
        tbs.append(ASN1.rdnSequence(commonName: commonName))
        tbs.append(ASN1.rsaPublicKeyInfo(publicKeyData))

        let tbsData = ASN1.sequence(tbs)

        guard let signature = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            tbsData as CFData,
            nil
        ) as Data? else {
            throw NSError(domain: "CertGen", code: -2, userInfo: [NSLocalizedDescriptionKey: "Signing failed"])
        }

        var cert = Data()
        cert.append(tbsData)
        cert.append(ASN1.sha256WithRSAAlgorithm())
        cert.append(ASN1.bitString(signature))

        return ASN1.sequence(cert)
    }

    // MARK: - Create SecIdentity from stored cert + key

    private static let identityTag = "com.googletv-remote.tls-identity"

    /// Adds cert and private key to Keychain persistently and retrieves the SecIdentity.
    /// Items must stay in Keychain for the TLS connection to work.
    static func createIdentity(certDER: Data, privateKeyData: Data) throws -> (SecIdentity, SecCertificate) {
        guard let certRef = SecCertificateCreateWithData(nil, certDER as CFData) else {
            throw NSError(domain: "CertGen", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid certificate data"])
        }

        // Restore private key from external representation
        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateWithData(privateKeyData as CFData, keyAttributes as CFDictionary, &error) else {
            throw error?.takeRetainedValue() ?? NSError(domain: "CertGen", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to restore private key"])
        }

        // Clean up any previous identity items
        cleanupIdentity()

        // Add cert to Keychain (persistent)
        let certQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: certRef,
            kSecAttrLabel as String: identityTag,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let certStatus = SecItemAdd(certQuery as CFDictionary, nil)
        guard certStatus == errSecSuccess else {
            throw NSError(domain: "CertGen", code: -6, userInfo: [NSLocalizedDescriptionKey: "Failed to add cert to Keychain: \(certStatus)"])
        }

        // Add private key to Keychain (persistent)
        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecValueRef as String: privateKey,
            kSecAttrLabel as String: identityTag,
            kSecAttrApplicationTag as String: identityTag.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let keyStatus = SecItemAdd(keyQuery as CFDictionary, nil)
        guard keyStatus == errSecSuccess else {
            SecItemDelete(certQuery as CFDictionary)
            throw NSError(domain: "CertGen", code: -7, userInfo: [NSLocalizedDescriptionKey: "Failed to add key to Keychain: \(keyStatus)"])
        }

        // Retrieve identity (cert + key matched by Keychain)
        let identityQuery: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var identityRef: AnyObject?
        let idStatus = SecItemCopyMatching(identityQuery as CFDictionary, &identityRef)

        guard idStatus == errSecSuccess, let identity = identityRef as! SecIdentity? else {
            throw NSError(domain: "CertGen", code: -8, userInfo: [NSLocalizedDescriptionKey: "Failed to create identity: \(idStatus)"])
        }

        return (identity, certRef)
    }

    /// Remove persistent identity items from Keychain
    static func cleanupIdentity() {
        let certQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: identityTag
        ]
        SecItemDelete(certQuery as CFDictionary)

        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrLabel as String: identityTag
        ]
        SecItemDelete(keyQuery as CFDictionary)
    }
}

// MARK: - ASN.1 DER Encoding Helpers

enum ASN1 {
    static let tagSequence: UInt8 = 0x30
    static let tagSet: UInt8 = 0x31
    static let tagInteger: UInt8 = 0x02
    static let tagBitString: UInt8 = 0x03
    static let tagOctetString: UInt8 = 0x04
    static let tagOID: UInt8 = 0x06
    static let tagUTF8String: UInt8 = 0x0C
    static let tagUTCTime: UInt8 = 0x17

    static func lengthEncoding(_ length: Int) -> Data {
        if length < 128 {
            return Data([UInt8(length)])
        } else if length < 256 {
            return Data([0x81, UInt8(length)])
        } else {
            return Data([0x82, UInt8(length >> 8), UInt8(length & 0xFF)])
        }
    }

    static func wrap(tag: UInt8, _ content: Data) -> Data {
        var result = Data([tag])
        result.append(lengthEncoding(content.count))
        result.append(content)
        return result
    }

    static func sequence(_ content: Data) -> Data { wrap(tag: tagSequence, content) }
    static func set(_ content: Data) -> Data { wrap(tag: tagSet, content) }
    static func integer(_ value: Data) -> Data { wrap(tag: tagInteger, value) }
    static func octetString(_ content: Data) -> Data { wrap(tag: tagOctetString, content) }
    static func utf8String(_ string: String) -> Data { wrap(tag: tagUTF8String, Data(string.utf8)) }
    static func utcTime(_ string: String) -> Data { wrap(tag: tagUTCTime, Data(string.utf8)) }

    static func bitString(_ content: Data) -> Data {
        var bs = Data([0x00])
        bs.append(content)
        return wrap(tag: tagBitString, bs)
    }

    static func oid(_ bytes: [UInt8]) -> Data { wrap(tag: tagOID, Data(bytes)) }

    static func contextTag(_ tag: Int, value: Data) -> Data {
        wrap(tag: UInt8(0xA0 | tag), value)
    }

    static func sha256WithRSAAlgorithm() -> Data {
        let oidBytes: [UInt8] = [0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B]
        var content = oid(oidBytes)
        content.append(Data([0x05, 0x00]))
        return sequence(content)
    }

    static func rdnSequence(commonName: String) -> Data {
        let cnOID = oid([0x55, 0x04, 0x03])
        var atv = cnOID
        atv.append(utf8String(commonName))
        let rdnSet = set(sequence(atv))
        return sequence(rdnSet)
    }

    static func validity(years: Int) -> Data {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMddHHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let notBefore = utcTime(formatter.string(from: Date()))
        let notAfter = utcTime(formatter.string(from: Calendar.current.date(byAdding: .year, value: years, to: Date())!))
        var content = notBefore
        content.append(notAfter)
        return sequence(content)
    }

    static func rsaPublicKeyInfo(_ publicKeyData: Data) -> Data {
        let rsaOID = oid([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01])
        var alg = rsaOID
        alg.append(Data([0x05, 0x00]))
        let algId = sequence(alg)

        var content = algId
        content.append(bitString(publicKeyData))
        return sequence(content)
    }
}
