import SwiftUI

public struct MetricCard: View {
    public let icon: String
    public let title: String
    public let value: String
    public let subtitle: String
    public let iconColor: Color

    public init(icon: String, title: String, value: String, subtitle: String, iconColor: Color = .accentColor) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.iconColor = iconColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
                Spacer()
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(10)
        .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

public struct ActionButton: View {
    public let title: String
    public let subtitle: String?
    public let icon: String
    public let color: Color
    public let isDisabled: Bool
    public let isLoading: Bool
    public let action: () -> Void

    public init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = .accentColor,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    if let sub = subtitle, !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 9))
                            .opacity(0.8)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(minHeight: 30)
            .foregroundColor(.white)
            .background(isDisabled ? Color.gray : color)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }
}
