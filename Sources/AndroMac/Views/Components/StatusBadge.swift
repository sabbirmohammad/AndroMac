import SwiftUI

public struct StatusBadge: View {
    public let state: EmulatorState

    public init(state: EmulatorState) {
        self.state = state
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state.statusColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(state.statusColor.opacity(0.4), lineWidth: state.isTransitioning ? 3 : 0)
                        .scaleEffect(state.isTransitioning ? 1.4 : 1.0)
                        .animation(state.isTransitioning ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: state.isTransitioning)
                )

            Text(state.statusTitle)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(state.statusColor.opacity(0.12))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(state.statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}
