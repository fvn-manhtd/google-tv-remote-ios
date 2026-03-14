import SwiftUI

struct ManualIPSheet: View {
    let onAdd: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var ipAddress = ""
    @State private var validationError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("IP Address (e.g. 192.168.1.100)", text: $ipAddress)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: ipAddress) { _ in
                            validationError = nil
                        }
                } header: {
                    Text("TV IP Address")
                } footer: {
                    if let error = validationError {
                        Text(error)
                            .foregroundStyle(.red)
                    } else {
                        Text("Enter the IP address of your Google TV device. You can find this in Settings > Network on your TV.")
                    }
                }
            }
            .navigationTitle("Add TV Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = ipAddress.trimmingCharacters(in: .whitespaces)
                        if validateIP(trimmed) {
                            onAdd(trimmed)
                            dismiss()
                        }
                    }
                    .disabled(ipAddress.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func validateIP(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else {
            validationError = "Invalid IP address format. Expected format: 192.168.1.100"
            return false
        }
        for part in parts {
            guard let num = Int(part), num >= 0, num <= 255 else {
                validationError = "Each segment must be a number between 0 and 255."
                return false
            }
        }
        return true
    }
}
