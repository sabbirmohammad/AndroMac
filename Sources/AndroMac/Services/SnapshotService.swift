import Foundation

public final class SnapshotService: Sendable {
    public static let shared = SnapshotService()

    private init() {}

    public var avdHomeDirectory: String {
        let home = NSHomeDirectory()
        return "\(home)/.android/avd"
    }

    public func listSnapshots(avdName: String = "AndroMac_Tablet") -> [EmulatorSnapshot] {
        let snapshotsDir = "\(avdHomeDirectory)/\(avdName).avd/snapshots"
        let fm = FileManager.default

        guard let contents = try? fm.contentsOfDirectory(atPath: snapshotsDir) else {
            return []
        }

        var results: [EmulatorSnapshot] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        for item in contents {
            if item.hasPrefix(".") { continue }
            let itemPath = "\(snapshotsDir)/\(item)"
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: itemPath, isDirectory: &isDir), isDir.boolValue {
                let attrs = try? fm.attributesOfItem(atPath: itemPath)
                let modDate = attrs?[.modificationDate] as? Date ?? Date()

                // Calculate directory size
                var totalBytes: Int64 = 0
                if let enumerator = fm.enumerator(atPath: itemPath) {
                    for case let subfile as String in enumerator {
                        let subpath = "\(itemPath)/\(subfile)"
                        if let subAttrs = try? fm.attributesOfItem(atPath: subpath),
                           let size = subAttrs[.size] as? Int64 {
                            totalBytes += size
                        }
                    }
                }

                let byteFormatter = ByteCountFormatter()
                byteFormatter.countStyle = .file
                let sizeStr = byteFormatter.string(fromByteCount: totalBytes)

                results.append(EmulatorSnapshot(
                    name: item,
                    createdDate: dateFormatter.string(from: modDate),
                    sizeFormatted: sizeStr,
                    isCurrent: item == "default_boot"
                ))
            }
        }

        return results.sorted { $0.createdDate > $1.createdDate }
    }

    public func saveSnapshot(name: String, adbPath: String, serial: String) async throws {
        let cleanName = name.replacingOccurrences(of: " ", with: "_")
        _ = try await ADBService.shared.executeCommand(
            adbPath: adbPath,
            serial: serial,
            arguments: ["emu", "avd", "snapshot", "save", cleanName]
        )
    }

    public func loadSnapshot(name: String, adbPath: String, serial: String) async throws {
        _ = try await ADBService.shared.executeCommand(
            adbPath: adbPath,
            serial: serial,
            arguments: ["emu", "avd", "snapshot", "load", name]
        )
    }

    public func deleteSnapshot(name: String, adbPath: String?, serial: String?, avdName: String = "AndroMac_Tablet") async throws {
        if let adb = adbPath, let s = serial {
            _ = try? await ADBService.shared.executeCommand(
                adbPath: adb,
                serial: s,
                arguments: ["emu", "avd", "snapshot", "delete", name]
            )
        }

        let snapshotPath = "\(avdHomeDirectory)/\(avdName).avd/snapshots/\(name)"
        if FileManager.default.fileExists(atPath: snapshotPath) {
            try FileManager.default.removeItem(atPath: snapshotPath)
        }
    }
}
