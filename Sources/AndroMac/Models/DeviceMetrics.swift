import Foundation

public struct DeviceMetrics: Equatable, Sendable {
    public var model: String = "Unknown"
    public var androidVersion: String = "Unknown"
    public var apiLevel: Int = 0
    public var resolution: String = "2560x1600"
    public var density: Int = 280
    public var cpuUsagePercent: Double = 0.0
    public var memoryUsageMB: Int = 0
    public var activeSerial: String = ""
    public var isPlayStoreAvailable: Bool = false
    public var bootTimeSeconds: Double = 0.0
    public var uptime: String = "00:00:00"

    public static let placeholder = DeviceMetrics()
}
