import Foundation

public enum DeviceMode: String, Codable, CaseIterable, Sendable {
    case laptop = "laptop"
    case tablet = "tablet"

    public var displayName: String {
        switch self {
        case .laptop: return "💻 Laptop / Desktop Mode (Recommended)"
        case .tablet: return "📱 Tablet Mode"
        }
    }

    public var shortName: String {
        switch self {
        case .laptop: return "Laptop Mode"
        case .tablet: return "Tablet Mode"
        }
    }

    public var icon: String {
        switch self {
        case .laptop: return "laptopcomputer"
        case .tablet: return "ipad.landscape"
        }
    }

    public var description: String {
        switch self {
        case .laptop:
            return "Freeform floating multi-windowing, desktop taskbar, resizable apps, and optimized mouse/keyboard workflow for Mac."
        case .tablet:
            return "Classic full-screen landscape layout (16:10) with split-screen touch-focused multitasking."
        }
    }
}

public struct ResolutionPreset: Identifiable, Hashable, Codable, Sendable {
    public var id: String { "\(width)x\(height)" }
    public let name: String
    public let width: Int
    public let height: Int
    public let aspectRatio: String
    public let description: String

    public static let presets: [ResolutionPreset] = [
        ResolutionPreset(name: "MacBook Air 13\" Native", width: 2560, height: 1600, aspectRatio: "16:10", description: "Default native MacBook Air Retina resolution"),
        ResolutionPreset(name: "MacBook Pro 14\" Scaled", width: 3024, height: 1964, aspectRatio: "16:10", description: "High-DPI crisp rendering for MacBook Pro 14\""),
        ResolutionPreset(name: "MacBook Pro 16\" Scaled", width: 3072, height: 1920, aspectRatio: "16:10", description: "Expansive workspace for MacBook Pro 16\""),
        ResolutionPreset(name: "Full HD 16:9 Laptop", width: 1920, height: 1080, aspectRatio: "16:9", description: "Standard 1080p widescreen laptop display"),
        ResolutionPreset(name: "Balanced 16:10 Laptop", width: 1920, height: 1200, aspectRatio: "16:10", description: "Optimized battery, fast frame rates & smooth rendering"),
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
        DensityPreset(dpi: 200, name: "200 DPI (High-Density Laptop)", description: "Compact UI, maximal screen space for multiple floating windows"),
        DensityPreset(dpi: 240, name: "240 DPI (Spacious Laptop - Recommended)", description: "Smaller icons, expansive workspace, true desktop-laptop experience"),
        DensityPreset(dpi: 280, name: "280 DPI (Standard Balanced)", description: "Optimal balance for 2560x1600 display with desktop taskbar"),
        DensityPreset(dpi: 320, name: "320 DPI (Large UI)", description: "Larger text and buttons, touch-friendly styling"),
        DensityPreset(dpi: 400, name: "400 DPI (Extra Large)", description: "High accessibility scale")
    ]
}

public struct TabletConfig: Codable, Equatable, Sendable {
    public var avdName: String
    public var displayName: String
    public var deviceMode: DeviceMode
    public var enableFreeformWindows: Bool
    public var enableDesktopMode: Bool
    public var forceResizableActivities: Bool
    public var width: Int
    public var height: Int
    public var density: Int
    public var ramMB: Int
    public var cpuCores: Int
    public var storageGB: Int
    public var heapSizeMB: Int
    public var orientation: String
    public var showDeviceFrame: Bool
    public var playStoreEnabled: Bool
    public var gpuMode: String
    public var coldBoot: Bool
    public var bootAnim: Bool
    public var keycodeForwarding: Bool

    public init(
        avdName: String = "AndroMac_Laptop",
        displayName: String = "AndroMac Laptop",
        deviceMode: DeviceMode = .laptop,
        enableFreeformWindows: Bool = true,
        enableDesktopMode: Bool = true,
        forceResizableActivities: Bool = true,
        width: Int = 2560,
        height: Int = 1600,
        density: Int = 240,
        ramMB: Int = 3072,
        cpuCores: Int = 4,
        storageGB: Int = 8,
        heapSizeMB: Int = 576,
        orientation: String = "landscape",
        showDeviceFrame: Bool = false,
        playStoreEnabled: Bool = true,
        gpuMode: String = "auto",
        coldBoot: Bool = false,
        bootAnim: Bool = false,
        keycodeForwarding: Bool = true
    ) {
        self.avdName = avdName
        self.displayName = displayName
        self.deviceMode = deviceMode
        self.enableFreeformWindows = enableFreeformWindows
        self.enableDesktopMode = enableDesktopMode
        self.forceResizableActivities = forceResizableActivities
        self.width = width
        self.height = height
        self.density = density
        self.ramMB = ramMB
        self.cpuCores = cpuCores
        self.storageGB = storageGB
        self.heapSizeMB = heapSizeMB
        self.orientation = orientation
        self.showDeviceFrame = showDeviceFrame
        self.playStoreEnabled = playStoreEnabled
        self.gpuMode = gpuMode
        self.coldBoot = coldBoot
        self.bootAnim = bootAnim
        self.keycodeForwarding = keycodeForwarding
    }

    public static let `default` = TabletConfig()

    enum CodingKeys: String, CodingKey {
        case avdName, displayName, deviceMode, enableFreeformWindows, enableDesktopMode, forceResizableActivities
        case width, height, density, ramMB, cpuCores, storageGB, heapSizeMB, orientation
        case showDeviceFrame, playStoreEnabled, gpuMode, coldBoot, bootAnim, keycodeForwarding
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.avdName = try container.decodeIfPresent(String.self, forKey: .avdName) ?? "AndroMac_Laptop"
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? "AndroMac Laptop"
        self.deviceMode = try container.decodeIfPresent(DeviceMode.self, forKey: .deviceMode) ?? .laptop
        self.enableFreeformWindows = try container.decodeIfPresent(Bool.self, forKey: .enableFreeformWindows) ?? true
        self.enableDesktopMode = try container.decodeIfPresent(Bool.self, forKey: .enableDesktopMode) ?? true
        self.forceResizableActivities = try container.decodeIfPresent(Bool.self, forKey: .forceResizableActivities) ?? true
        self.width = try container.decodeIfPresent(Int.self, forKey: .width) ?? 2560
        self.height = try container.decodeIfPresent(Int.self, forKey: .height) ?? 1600
        self.density = try container.decodeIfPresent(Int.self, forKey: .density) ?? 240
        self.ramMB = try container.decodeIfPresent(Int.self, forKey: .ramMB) ?? 3072
        self.cpuCores = try container.decodeIfPresent(Int.self, forKey: .cpuCores) ?? 4
        self.storageGB = try container.decodeIfPresent(Int.self, forKey: .storageGB) ?? 8
        self.heapSizeMB = try container.decodeIfPresent(Int.self, forKey: .heapSizeMB) ?? 576
        self.orientation = try container.decodeIfPresent(String.self, forKey: .orientation) ?? "landscape"
        self.showDeviceFrame = try container.decodeIfPresent(Bool.self, forKey: .showDeviceFrame) ?? false
        self.playStoreEnabled = try container.decodeIfPresent(Bool.self, forKey: .playStoreEnabled) ?? true
        self.gpuMode = try container.decodeIfPresent(String.self, forKey: .gpuMode) ?? "auto"
        self.coldBoot = try container.decodeIfPresent(Bool.self, forKey: .coldBoot) ?? false
        self.bootAnim = try container.decodeIfPresent(Bool.self, forKey: .bootAnim) ?? false
        self.keycodeForwarding = try container.decodeIfPresent(Bool.self, forKey: .keycodeForwarding) ?? true
    }

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
