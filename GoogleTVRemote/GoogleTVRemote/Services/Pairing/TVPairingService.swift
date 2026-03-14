import Foundation
import AndroidTVRemoteControl

@MainActor
class TVPairingService: ObservableObject {
    @Published var status: PairingStatus = .idle

    private var pairingManager: PairingManager?
    private let keychainService: KeychainService
    private let queue = DispatchQueue(label: "com.googletv-remote.pairing")

    init(keychainService: KeychainService = KeychainService()) {
        self.keychainService = keychainService
    }

    func startPairing(host: String) {
        status = .connecting

        do {
            // Load or generate client certificate
            let certDER: Data
            let privateKeyData: Data

            if let stored = try keychainService.loadCertificate() {
                certDER = stored.certDER
                privateKeyData = stored.privateKey
            } else {
                let result = try CertificateGenerator.generate()
                certDER = result.certDER
                privateKeyData = result.privateKeyData
                try keychainService.saveCertificate(certDER: certDER, privateKey: privateKeyData)
            }

            // Write DER cert to temp file for CertManager.getSecKey()
            let certURL = FileManager.default.temporaryDirectory.appendingPathComponent("client_cert.der")
            try certDER.write(to: certURL)

            // Create identity for TLS
            let (identity, certRef) = try CertificateGenerator.createIdentity(
                certDER: certDER,
                privateKeyData: privateKeyData
            )

            let cryptoManager = CryptoManager()
            cryptoManager.clientPublicCertificate = {
                return CertManager().getSecKey(certURL)
            }

            let tlsManager = TLSManager {
                // Provide the identity directly instead of using CertManager.cert()
                let identityDict: [String: Any] = [
                    kSecImportItemIdentity as String: identity,
                    kSecImportItemCertChain as String: [certRef] as CFArray
                ]
                return .Result([identityDict] as CFArray)
            }

            tlsManager.secTrustClosure = { secTrust in
                cryptoManager.serverPublicCertificate = {
                    if let serverKey = SecTrustCopyKey(secTrust) {
                        return .Result(serverKey)
                    }
                    return .Error(.secTrustCopyKeyError)
                }
            }

            pairingManager = PairingManager(tlsManager, cryptoManager)

            pairingManager?.stateChanged = { [weak self] state in
                Task { @MainActor in
                    self?.handlePairingState(state)
                }
            }

            pairingManager?.connect(host, Constants.DeviceInfo.appName, Constants.DeviceInfo.appName)

        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func submitPin(_ code: String) {
        guard validatePin(code) else {
            status = .failed("Invalid PIN. Must be 6 hex characters (0-9, A-F).")
            return
        }
        status = .validating
        pairingManager?.sendSecret(code)
    }

    func validatePin(_ code: String) -> Bool {
        let hex = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        return code.count == 6 && code.unicodeScalars.allSatisfy { hex.contains($0) }
    }

    private func handlePairingState(_ state: PairingManager.PairingState) {
        switch state {
        case .idle:
            status = .idle
        case .waitingCode:
            status = .waitingForCode
        case .successPaired:
            status = .success
        case .error(let error):
            status = .failed("Pairing error: \(error)")
        default:
            if case .connecting = status {} else if case .waitingForCode = status {} else {
                status = .connecting
            }
        }
    }

    func cancel() {
        pairingManager?.disconnect()
        pairingManager = nil
        status = .idle
    }
}
