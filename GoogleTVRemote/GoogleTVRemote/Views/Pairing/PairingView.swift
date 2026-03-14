import SwiftUI

struct PairingView: View {
    let device: TVDevice
    var onPairingSuccess: ((TVDevice) -> Void)?
    @StateObject private var viewModel = PairingViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var pinFieldFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image(systemName: "tv.and.mediabox")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("Pairing with \(device.name)")
                    .font(.title2.weight(.semibold))

                Text("A 6-character code should appear on your TV screen. Enter it below.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            switch viewModel.status {
            case .waitingForCode, .failed:
                VStack(spacing: 16) {
                    TextField("PIN Code (e.g. A1B2C3)", text: $viewModel.pinCode)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .frame(maxWidth: 280)
                        .focused($pinFieldFocused)
                        .onChange(of: viewModel.pinCode) { newValue in
                            let filtered = String(newValue.prefix(6))
                                .filter { "0123456789ABCDEFabcdef".contains($0) }
                                .uppercased()
                            if filtered != newValue {
                                viewModel.pinCode = filtered
                            }
                        }

                    if case .failed(let message) = viewModel.status {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button("Submit") {
                        viewModel.submitPin()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.pinCode.count != 6)
                }
                .onAppear { pinFieldFocused = true }

            case .connecting, .validating:
                ProgressView("Connecting...")

            case .success:
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Paired successfully!")
                        .font(.title3.weight(.medium))
                }

            case .idle:
                EmptyView()
            }

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(viewModel.status == .validating)
        .onAppear {
            viewModel.startPairing(device: device)
        }
        .onChange(of: viewModel.status) { newStatus in
            if case .success = newStatus {
                let pairedDevice = viewModel.markDeviceAsPaired()
                if let onPairingSuccess, let pairedDevice {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        onPairingSuccess(pairedDevice)
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
            }
        }
    }
}
