import Foundation

public struct SetupStep: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public var status: StepStatus
    public var detail: String?

    public enum StepStatus: Equatable, Sendable {
        case pending
        case inProgress
        case success
        case warning(String)
        case failed(String)
    }

    public init(id: String, title: String, description: String, status: StepStatus = .pending, detail: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.detail = detail
    }
}

public struct InstalledApp: Identifiable, Hashable, Sendable {
    public var id: String { packageName }
    public let packageName: String
    public let label: String
    public let isSystemApp: Bool

    public init(packageName: String, label: String, isSystemApp: Bool = false) {
        self.packageName = packageName
        self.label = label
        self.isSystemApp = isSystemApp
    }
}
