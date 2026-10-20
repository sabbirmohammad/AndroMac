import Foundation

public struct AVDInstance: Identifiable, Hashable, Sendable {
    public var id: String { name }
    public let name: String
    public let displayName: String
    public let resolution: String
    public let density: Int
    public let ramMB: Int
    public let cpuCores: Int
    public let storageGB: Int
    public let targetAndroid: String
    public let isCurrent: Bool
    public let isRunning: Bool

    public init(
        name: String,
        displayName: String,
        resolution: String,
        density: Int,
        ramMB: Int,
        cpuCores: Int,
        storageGB: Int,
        targetAndroid: String,
        isCurrent: Bool = false,
        isRunning: Bool = false
    ) {
        self.name = name
        self.displayName = displayName
        self.resolution = resolution
        self.density = density
        self.ramMB = ramMB
        self.cpuCores = cpuCores
        self.storageGB = storageGB
        self.targetAndroid = targetAndroid
        self.isCurrent = isCurrent
        self.isRunning = isRunning
    }
}
