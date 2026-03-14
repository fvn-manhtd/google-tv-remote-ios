import SwiftUI

@main
struct GoogleTVRemoteApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                DiscoveryView()
            }
            .environmentObject(appState)
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var lastConnectedTVId: String? {
        didSet {
            UserDefaults.standard.set(lastConnectedTVId, forKey: "last_tv_id")
        }
    }

    init() {
        lastConnectedTVId = UserDefaults.standard.string(forKey: "last_tv_id")
    }

    func lastConnectedDevice() -> TVDevice? {
        guard let savedId = lastConnectedTVId else { return nil }
        return TVDevice.loadAll().first { $0.id.uuidString == savedId }
    }
}
