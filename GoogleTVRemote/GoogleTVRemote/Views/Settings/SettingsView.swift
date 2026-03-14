import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showForgetAllAlert = false

    var body: some View {
        List {
            Section("Paired Devices") {
                if viewModel.pairedDevices.isEmpty {
                    Text("No paired devices")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.pairedDevices) { device in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.name)
                                    .font(.body.weight(.medium))
                                if !device.host.isEmpty {
                                    Text(device.host)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let mac = device.macAddress {
                                    Text("MAC: \(mac)")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()
                            if let lastConnected = device.lastConnected {
                                Text(lastConnected, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.forgetDevice(device)
                            } label: {
                                Label("Forget", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            Section("Wake-on-LAN") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Setup Guide")
                        .font(.body.weight(.medium))
                    Text("To use Wake-on-LAN, ensure your Google TV has WoL enabled in Settings > Network > Wake on wireless network. The TV's MAC address is automatically detected during discovery.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    showForgetAllAlert = true
                } label: {
                    Text("Forget All Devices")
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Forget All Devices?", isPresented: $showForgetAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Forget All", role: .destructive) {
                viewModel.forgetAllDevices()
            }
        } message: {
            Text("This will remove all paired devices and certificates. You will need to re-pair each device.")
        }
    }
}
