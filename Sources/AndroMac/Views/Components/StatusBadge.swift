import SwiftUI

public struct StatusBadge: View {
    public let state: EmulatorState

    public init(state: EmulatorState) {
        self.state = state
    }

    public var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(state.statusColor)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(state.statusColor.opacity(0.4), lineWidth: state.isTransitioning ? 3 : 0)
                        .scaleEffect(state.isTransitioning ? 1.4 : 1.0)
                        .animation(state.isTransitioning ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: state.isTransitioning)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(state.statusTitle)
                    .font(.system(size: 13, weight: .semibold))
                Text(state.statusTitleBn)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(state.statusColor.opacity(0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(state.statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}
