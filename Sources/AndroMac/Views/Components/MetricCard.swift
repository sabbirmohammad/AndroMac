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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                Spacer()
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .lineLimit(1)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(minWidth: 140, maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
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
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 10))
                            .opacity(0.8)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundColor(.white)
            .background(isDisabled ? Color.gray : color)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }
}
