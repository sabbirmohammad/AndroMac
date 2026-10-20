import Foundation

public final class InstanceManager: Sendable {
    public static let shared = InstanceManager()

    private init() {}

    public var avdHomeDirectory: String {
        let home = NSHomeDirectory()
        return "\(home)/.android/avd"
    }

    public func listInstances(currentAVDName: String, isEmulatorRunning: Bool) -> [AVDInstance] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: avdHomeDirectory) else {
            return []
        }

        var instances: [AVDInstance] = []
        let iniFiles = files.filter { $0.hasSuffix(".ini") }

        for iniFile in iniFiles {
            let avdName = String(iniFile.dropLast(4))
            let avdDir = "\(avdHomeDirectory)/\(avdName).avd"
            let configIniPath = "\(avdDir)/config.ini"

            guard fm.fileExists(atPath: configIniPath) else { continue }

            var displayName = avdName
            var width = 2560
            var height = 1600
            var density = 280
            var ramMB = 3072
            var cpuCores = 4
            var storageGB = 8
            var targetAndroid = "Android 16"

            if let content = try? String(contentsOfFile: configIniPath, encoding: .utf8) {
                let lines = content.components(separatedBy: .newlines)
                for line in lines {
                    let parts = line.split(separator: "=", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
                    if parts.count == 2 {
                        let key = parts[0]
                        let val = parts[1]
                        switch key {
                        case "avd.ini.displayname": displayName = val
                        case "hw.lcd.width": width = Int(val) ?? width
                        case "hw.lcd.height": height = Int(val) ?? height
                        case "hw.lcd.density": density = Int(val) ?? density
                        case "hw.ramSize": ramMB = Int(val) ?? ramMB
                        case "hw.cpu.ncore": cpuCores = Int(val) ?? cpuCores
                        case "disk.dataPartition.size":
                            let clean = val.replacingOccurrences(of: "G", with: "").replacingOccurrences(of: "M", with: "")
                            storageGB = Int(clean) ?? storageGB
                        case "image.sysdir.1":
                            if val.contains("android-36") { targetAndroid = "Android 16" }
                            else if val.contains("android-35") { targetAndroid = "Android 15" }
                            else if val.contains("android-34") { targetAndroid = "Android 14" }
                        default: break
                        }
                    }
                }
            }

            let isCurrent = (avdName == currentAVDName)
            let isRunning = isCurrent && isEmulatorRunning

            instances.append(AVDInstance(
                name: avdName,
                displayName: displayName,
                resolution: "\(width)x\(height)",
                density: density,
                ramMB: ramMB,
                cpuCores: cpuCores,
                storageGB: storageGB,
                targetAndroid: targetAndroid,
                isCurrent: isCurrent,
                isRunning: isRunning
            ))
        }

        return instances.sorted { $0.isCurrent && !$1.isCurrent }
    }

    public func createInstance(
        name: String,
        displayName: String,
        width: Int,
        height: Int,
        density: Int,
        ramMB: Int,
        cpuCores: Int,
        storageGB: Int,
        report: EnvironmentReport
    ) throws {
        var newConfig = TabletConfig()
        newConfig.avdName = name
        newConfig.displayName = displayName
        newConfig.width = width
        newConfig.height = height
        newConfig.density = density
        newConfig.ramMB = ramMB
        newConfig.cpuCores = cpuCores
        newConfig.storageGB = storageGB

        try AVDManager.shared.configureAVD(config: newConfig, report: report)
    }

    public func cloneInstance(sourceName: String, targetName: String, targetDisplayName: String) throws {
        let fm = FileManager.default
        let sourceDir = "\(avdHomeDirectory)/\(sourceName).avd"
        let targetDir = "\(avdHomeDirectory)/\(targetName).avd"
        let sourceIni = "\(avdHomeDirectory)/\(sourceName).ini"
        let targetIni = "\(avdHomeDirectory)/\(targetName).ini"

        guard fm.fileExists(atPath: sourceDir), fm.fileExists(atPath: sourceIni) else {
            throw NSError(domain: "InstanceManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Source instance '\(sourceName)' does not exist."])
        }

        // Copy AVD directory
        if fm.fileExists(atPath: targetDir) {
            try fm.removeItem(atPath: targetDir)
        }
        try fm.copyItem(atPath: sourceDir, toPath: targetDir)

        // Write new .ini pointing to targetDir
        if let iniContent = try? String(contentsOfFile: sourceIni, encoding: .utf8) {
            let updated = iniContent
                .replacingOccurrences(of: "\(sourceName).avd", with: "\(targetName).avd")
                .replacingOccurrences(of: "path.rel=avd/\(sourceName).avd", with: "path.rel=avd/\(targetName).avd")
            try updated.write(toFile: targetIni, atomically: true, encoding: .utf8)
        }

        // Update target config.ini
        let targetConfigIni = "\(targetDir)/config.ini"
        if let configContent = try? String(contentsOfFile: targetConfigIni, encoding: .utf8) {
            var updated = configContent
                .replacingOccurrences(of: "avd.id=\(sourceName)", with: "avd.id=\(targetName)")
                .replacingOccurrences(of: "avd.name=\(sourceName)", with: "avd.name=\(targetName)")
            if let regex = try? NSRegularExpression(pattern: "avd\\.ini\\.displayname=.*") {
                let range = NSRange(location: 0, length: updated.utf16.count)
                updated = regex.stringByReplacingMatches(in: updated, range: range, withTemplate: "avd.ini.displayname=\(targetDisplayName)")
            }
            try updated.write(toFile: targetConfigIni, atomically: true, encoding: .utf8)
        }
    }

    public func deleteInstance(name: String) throws {
        let fm = FileManager.default
        let iniFile = "\(avdHomeDirectory)/\(name).ini"
        let avdDir = "\(avdHomeDirectory)/\(name).avd"

        if fm.fileExists(atPath: iniFile) {
            try fm.removeItem(atPath: iniFile)
        }
        if fm.fileExists(atPath: avdDir) {
            try fm.removeItem(atPath: avdDir)
        }
    }
}
