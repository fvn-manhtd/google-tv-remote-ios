import SwiftUI

struct TVDeviceRow: View {
    let device: TVDevice

    var body: some View {
        HStack {
            Image(systemName: "tv")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.body.weight(.medium))

                HStack(spacing: 4) {
                    switch device.resolutionStatus {
                    case .resolved:
                        if !device.host.isEmpty {
                            Text(device.host)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    case .resolving:
                        ProgressView()
                            .controlSize(.mini)
                        Text("Resolving...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    case .failed:
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("Could not resolve")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    case .unresolved:
                        Text("Discovered")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if device.isPaired {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(device.name), \(device.isPaired ? "paired" : "not paired")")
    }
}
