import Foundation

public struct EmulatorSnapshot: Identifiable, Hashable, Sendable {
    public var id: String { name }
    public let name: String
    public let createdDate: String
    public let sizeFormatted: String
    public let isCurrent: Bool

    public init(name: String, createdDate: String, sizeFormatted: String, isCurrent: Bool = false) {
        self.name = name
        self.createdDate = createdDate
        self.sizeFormatted = sizeFormatted
        self.isCurrent = isCurrent
    }
}
