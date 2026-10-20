import Foundation

public struct ResolutionPreset: Identifiable, Hashable, Codable, Sendable {
    public var id: String { "\(width)x\(height)" }
    public let name: String
    public let width: Int
    public let height: Int
    public let aspectRatio: String
    public let description: String

    public static let presets: [ResolutionPreset] = [
        ResolutionPreset(name: "MacBook Air 13\" Native", width: 2560, height: 1600, aspectRatio: "16:10", description: "Default native MacBook Air Retina resolution"),
        ResolutionPreset(name: "MacBook Pro 14\" Scaled", width: 3024, height: 1964, aspectRatio: "16:10", description: "High-DPI crisp rendering for MacBook Pro"),
        ResolutionPreset(name: "Balanced 16:10", width: 1920, height: 1200, aspectRatio: "16:10", description: "Optimized battery and smooth rendering"),
        ResolutionPreset(name: "Compact 16:10", width: 1680, height: 1050, aspectRatio: "16:10", description: "Low memory footprint"),
        ResolutionPreset(name: "Ultra-Light 16:10", width: 1440, height: 900, aspectRatio: "16:10", description: "Fastest frame rates and lowest power draw")
    ]
}

public struct DensityPreset: Identifiable, Hashable, Codable, Sendable {
    public var id: Int { dpi }
    public let dpi: Int
    public let name: String
    public let description: String

    public static let presets: [DensityPreset] = [
        DensityPreset(dpi: 240, name: "240 DPI (Spacious)", description: "Smaller icons, expansive workspace, true desktop-tablet experience"),
        DensityPreset(dpi: 280, name: "280 DPI (Standard Tablet - Recommended)", description: "Optimal balance for 2560x1600 display with tablet taskbar"),
        DensityPreset(dpi: 320, name: "320 DPI (Large UI)", description: "Larger text and buttons, touch-friendly styling"),
        DensityPreset(dpi: 400, name: "400 DPI (Extra Large)", description: "High accessibility scale")
    ]
}

public struct TabletConfig: Codable, Equatable, Sendable {
    public var avdName: String = "AndroMac_Tablet"
    public var displayName: String = "AndroMac Tablet"
    public var width: Int = 2560
    public var height: Int = 1600
    public var density: Int = 280
    public var ramMB: Int = 3072
    public var cpuCores: Int = 4
    public var storageGB: Int = 8
    public var heapSizeMB: Int = 576
    public var orientation: String = "landscape"
    public var showDeviceFrame: Bool = false
    public var playStoreEnabled: Bool = true
    public var gpuMode: String = "auto"
    public var coldBoot: Bool = false
    public var bootAnim: Bool = false
    public var keycodeForwarding: Bool = true

    public static let `default` = TabletConfig()

    public static func load() -> TabletConfig {
        guard let data = UserDefaults.standard.data(forKey: "AndroMac_TabletConfig"),
              let config = try? JSONDecoder().decode(TabletConfig.self, from: data) else {
            return .default
        }
        return config
    }

    public func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "AndroMac_TabletConfig")
        }
    }
}
