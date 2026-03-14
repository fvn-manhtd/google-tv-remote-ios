import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = DiscoveryViewModel()
    @State private var showManualIP = false
    @State private var selectedDevice: TVDevice?
    @State private var navigateToPairing = false
    @State private var navigateToRemote = false
    @State private var hasAutoConnected = false

    var body: some View {
        List {
            if viewModel.isScanning && viewModel.devices.isEmpty {
                HStack {
                    ProgressView()
                    Text("Scanning for TVs...")
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(viewModel.devices) { device in
                TVDeviceRow(device: device)
                    .onTapGesture {
                        handleDeviceTap(device)
                    }
            }
        }
        .refreshable {
            viewModel.refresh()
        }
        .navigationTitle("Google TV Remote")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showManualIP = true }) {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showManualIP) {
            ManualIPSheet(onAdd: { host in
                let device = viewModel.addManualDevice(host: host)
                selectedDevice = device
                navigateToPairing = true
            })
        }
        .navigationDestination(isPresented: $navigateToPairing) {
            if let device = selectedDevice {
                PairingView(device: device, onPairingSuccess: { pairedDevice in
                    navigateToPairing = false
                    selectedDevice = pairedDevice
                    appState.lastConnectedTVId = pairedDevice.id.uuidString
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToRemote = true
                    }
                })
            }
        }
        .navigationDestination(isPresented: $navigateToRemote) {
            if let device = selectedDevice {
                RemoteControlView(viewModel: RemoteViewModel(device: device))
            }
        }
        .onAppear {
            viewModel.startScan()
            // Auto-connect disabled to show discovery list
            // autoConnectIfNeeded()
        }
    }

    private func handleDeviceTap(_ device: TVDevice) {
        if device.isPaired {
            selectedDevice = device
            appState.lastConnectedTVId = device.id.uuidString
            navigateToRemote = true
        } else {
            resolveAndNavigate(device)
        }
    }

    private func resolveAndNavigate(_ device: TVDevice) {
        if device.host.isEmpty && device.resolutionStatus != .resolving {
            // Attempt on-demand resolution if auto-resolve didn't complete
            viewModel.resolveDevice(device) { resolvedHost in
                var resolved = device
                if let host = resolvedHost {
                    resolved.host = host
                    resolved.resolutionStatus = .resolved
                }
                selectedDevice = resolved
                navigateToPairing = true
            }
        } else if device.resolutionStatus == .resolving {
            // Still resolving — wait briefly and retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                resolveAndNavigate(device)
            }
        } else {
            selectedDevice = device
            navigateToPairing = true
        }
    }

    private func autoConnectIfNeeded() {
        guard !hasAutoConnected else { return }
        hasAutoConnected = true

        if let lastDevice = appState.lastConnectedDevice(), lastDevice.isPaired {
            selectedDevice = lastDevice
            navigateToRemote = true
        }
    }
}
