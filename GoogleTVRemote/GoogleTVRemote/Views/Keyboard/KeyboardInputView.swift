import SwiftUI

struct KeyboardInputView: View {
    let remoteService: TVRemoteService
    @StateObject private var viewModel: KeyboardViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var textFieldFocused: Bool

    init(remoteService: TVRemoteService) {
        self.remoteService = remoteService
        _viewModel = StateObject(wrappedValue: KeyboardViewModel(remoteService: remoteService))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Type text to send to your TV")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Type here...", text: $viewModel.text)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .focused($textFieldFocused)
                    .onSubmit {
                        viewModel.sendText(viewModel.text)
                        viewModel.text = ""
                    }

                HStack(spacing: 16) {
                    Button("Send") {
                        viewModel.sendText(viewModel.text)
                        viewModel.text = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.text.isEmpty)

                    Button("Backspace") {
                        viewModel.sendBackspace()
                    }
                    .buttonStyle(.bordered)

                    Button("Enter") {
                        viewModel.sendEnter()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Keyboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                textFieldFocused = true
            }
        }
        .presentationDetents([.medium, .large])
    }
}
