import Foundation
import Security

class KeychainService {
    enum KeychainError: Error {
        case saveFailed(OSStatus)
        case loadFailed(OSStatus)
        case deleteFailed(OSStatus)
        case dataConversionFailed
    }

    func saveData(_ data: Data, for account: String) throws {
        try? deleteData(for: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func loadData(for account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw KeychainError.loadFailed(status)
        }
        return result as? Data
    }

    func deleteData(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.Keychain.service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    func hasData(for account: String) -> Bool {
        return (try? loadData(for: account)) != nil
    }

    // MARK: - Certificate-specific convenience

    func saveCertificate(certDER: Data, privateKey: Data) throws {
        try saveData(certDER, for: Constants.Keychain.clientCertDER)
        try saveData(privateKey, for: Constants.Keychain.clientPrivateKey)
    }

    func loadCertificate() throws -> (certDER: Data, privateKey: Data)? {
        guard let certDER = try loadData(for: Constants.Keychain.clientCertDER),
              let privateKey = try loadData(for: Constants.Keychain.clientPrivateKey) else {
            return nil
        }
        return (certDER, privateKey)
    }

    func deleteCertificate() throws {
        try deleteData(for: Constants.Keychain.clientCertDER)
        try deleteData(for: Constants.Keychain.clientPrivateKey)
    }

    func hasCertificate() -> Bool {
        return hasData(for: Constants.Keychain.clientCertDER) &&
               hasData(for: Constants.Keychain.clientPrivateKey)
    }
}
