import Foundation

public struct EnvironmentReport: Equatable, Sendable {
    public let isAppleSilicon: Bool
    public let macArchitecture: String
    public let macOSVersion: String
    public let sdkPath: String?
    public let adbPath: String?
    public let emulatorPath: String?
    public let avdManagerPath: String?
    public let sdkManagerPath: String?
    public let availableSystemImages: [String]
    public let hasGooglePlayArm64Image: Bool
    public let isReadyToRun: Bool
    public let issues: [String]

    public var summary: String {
        if isReadyToRun {
            return "Environment is fully configured and ready."
        } else {
            return "Environment requires setup: \(issues.joined(separator: ", "))"
        }
    }
}

public final class EnvironmentDetector: Sendable {
    public static let shared = EnvironmentDetector()

    public init() {}

    public func detect() -> EnvironmentReport {
        let arch = getMacArchitecture()
        let isArm64 = arch == "arm64"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString

        let sdk = findAndroidSDK()
        let adb = sdk.flatMap { findBinary(named: "adb", in: "\($0)/platform-tools") }
        let emulator = sdk.flatMap { findBinary(named: "emulator", in: "\($0)/emulator") }
        let avdManager = sdk.flatMap { findAvdManager(in: $0) }
        let sdkManager = sdk.flatMap { findSdkManager(in: $0) }

        var images: [String] = []
        var hasGooglePlayArm64 = false
        if let sdkPath = sdk {
            let sysImagesPath = "\(sdkPath)/system-images"
            images = scanSystemImages(at: sysImagesPath)
            hasGooglePlayArm64 = images.contains { $0.contains("google_apis_playstore") && $0.contains("arm64") }
        }

        var issues: [String] = []
        if !isArm64 {
            issues.append("Non-Apple Silicon CPU detected (\(arch)). Apple Silicon (arm64) is required.")
        }
        if sdk == nil {
            issues.append("Android SDK not found. Install via Android Studio or command-line tools.")
        }
        if adb == nil {
            issues.append("adb tool missing in platform-tools.")
        }
        if emulator == nil {
            issues.append("Android emulator binary missing in SDK/emulator.")
        }
        if !hasGooglePlayArm64 {
            issues.append("No ARM64 Google Play system image found in SDK/system-images.")
        }

        let isReady = isArm64 && sdk != nil && adb != nil && emulator != nil && hasGooglePlayArm64

        return EnvironmentReport(
            isAppleSilicon: isArm64,
            macArchitecture: arch,
            macOSVersion: osVersion,
            sdkPath: sdk,
            adbPath: adb,
            emulatorPath: emulator,
            avdManagerPath: avdManager,
            sdkManagerPath: sdkManager,
            availableSystemImages: images,
            hasGooglePlayArm64Image: hasGooglePlayArm64,
            isReadyToRun: isReady,
            issues: issues
        )
    }

    private func getMacArchitecture() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machineMirror = Mirror(reflecting: sysinfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    private func findAndroidSDK() -> String? {
        if let custom = UserDefaults.standard.string(forKey: "CustomAndroidSDKPath"),
           FileManager.default.fileExists(atPath: custom) {
            return custom
        }

        if let home = ProcessInfo.processInfo.environment["ANDROID_HOME"],
           FileManager.default.fileExists(atPath: home) {
            return home
        }

        if let sdkRoot = ProcessInfo.processInfo.environment["ANDROID_SDK_ROOT"],
           FileManager.default.fileExists(atPath: sdkRoot) {
            return sdkRoot
        }

        let homeDir = NSHomeDirectory()
        let standardPaths = [
            "\(homeDir)/Library/Android/sdk",
            "/opt/homebrew/share/android-commandlinetools",
            "/usr/local/share/android-commandlinetools"
        ]

        for path in standardPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }

    private func findBinary(named name: String, in directory: String) -> String? {
        let fullPath = "\(directory)/\(name)"
        if FileManager.default.isExecutableFile(atPath: fullPath) {
            return fullPath
        }
        return nil
    }

    private func findAvdManager(in sdkPath: String) -> String? {
        let candidates = [
            "\(sdkPath)/cmdline-tools/latest/bin/avdmanager",
            "\(sdkPath)/cmdline-tools/bin/avdmanager",
            "\(sdkPath)/tools/bin/avdmanager"
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func findSdkManager(in sdkPath: String) -> String? {
        let candidates = [
            "\(sdkPath)/cmdline-tools/latest/bin/sdkmanager",
            "\(sdkPath)/cmdline-tools/bin/sdkmanager",
            "\(sdkPath)/tools/bin/sdkmanager"
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func scanSystemImages(at path: String) -> [String] {
        var results: [String] = []
        let fm = FileManager.default
        guard let apiDirs = try? fm.contentsOfDirectory(atPath: path) else { return results }

        for api in apiDirs {
            let apiPath = "\(path)/\(api)"
            guard let tags = try? fm.contentsOfDirectory(atPath: apiPath) else { continue }
            for tag in tags {
                let tagPath = "\(apiPath)/\(tag)"
                guard let abis = try? fm.contentsOfDirectory(atPath: tagPath) else { continue }
                for abi in abis {
                    let fullImgPath = "\(tagPath)/\(abi)/system.img"
                    if fm.fileExists(atPath: fullImgPath) {
                        results.append("system-images;\(api);\(tag);\(abi)")
                    }
                }
            }
        }
        return results
    }
}
