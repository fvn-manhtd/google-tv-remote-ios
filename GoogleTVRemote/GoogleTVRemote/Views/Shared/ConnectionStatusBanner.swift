import SwiftUI

struct ConnectionStatusBanner: View {
    let status: ConnectionStatus

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)

            if case .connecting = status {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.1))
    }

    private var statusColor: Color {
        switch status {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    private var statusText: String {
        switch status {
        case .connected(let app): return "Connected" + (app.map { " - \($0)" } ?? "")
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error(let msg): return msg
        }
    }
}
