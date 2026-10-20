import Foundation

public final class FileTransferService: Sendable {
    public static let shared = FileTransferService()

    private init() {}

    public func pushFile(
        at localURL: URL,
        destinationDir: String = "/sdcard/Download",
        adbPath: String,
        serial: String
    ) async throws {
        let filename = localURL.lastPathComponent
        let remotePath = "\(destinationDir)/\(filename)"

        _ = try await ADBService.shared.executeCommand(
            adbPath: adbPath,
            serial: serial,
            arguments: ["push", localURL.path, remotePath]
        )

        // Trigger Android Media Scanner so Photos/Files index it instantly
        let scanURI = "file://\(remotePath)"
        _ = try? await ADBService.shared.executeCommand(
            adbPath: adbPath,
            serial: serial,
            arguments: ["shell", "am", "broadcast", "-a", "android.intent.action.MEDIA_SCANNER_SCAN_FILE", "-d", scanURI]
        )
    }

    public func listFiles(
        directory: String = "/sdcard/Download",
        adbPath: String,
        serial: String
    ) async -> [AndroidFileItem] {
        guard let output = try? await ADBService.shared.executeCommand(
            adbPath: adbPath,
            serial: serial,
            arguments: ["shell", "ls", "-la", directory]
        ) else {
            return []
        }

        var items: [AndroidFileItem] = []
        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("total") { continue }

            let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
            // Typical ls -la output:
            // drwxrwx--- 2 root everybody 4096 2026-10-21 00:00 filename
            // -rw-rw---- 1 root everybody 1048576 2026-10-21 00:00 file.mp4
            if parts.count >= 8 {
                let permissions = String(parts[0])
                let isDir = permissions.hasPrefix("d")
                let sizeBytes = Int64(parts[4]) ?? 0
                let dateStr = "\(parts[5]) \(parts[6])"
                let name = parts[7...].joined(separator: " ")

                if name == "." || name == ".." { continue }

                let remotePath = "\(directory)/\(name)"
                items.append(AndroidFileItem(
                    name: name,
                    remotePath: remotePath,
                    sizeBytes: sizeBytes,
                    isDirectory: isDir,
                    modifiedDate: dateStr
                ))
            }
        }

        return items.sorted {
            if $0.isDirectory != $1.isDirectory {
                return $0.isDirectory && !$1.isDirectory
            }
            return $0.name.lowercased() < $1.name.lowercased()
        }
    }

    public func pullFile(
        remotePath: String,
        to localURL: URL,
        adbPath: String,
        serial: String
    ) async throws {
        _ = try await ADBService.shared.executeCommand(
            adbPath: adbPath,
            serial: serial,
            arguments: ["pull", remotePath, localURL.path]
        )
    }

    public func deleteFile(
        remotePath: String,
        adbPath: String,
        serial: String
    ) async throws {
        _ = try await ADBService.shared.executeCommand(
            adbPath: adbPath,
            serial: serial,
            arguments: ["shell", "rm", "-rf", remotePath]
        )
    }

    public func openDownloadsFolderInAndroid(adbPath: String, serial: String) async throws {
        // Open the Files app or downloads provider
        _ = try await ADBService.shared.executeCommand(
            adbPath: adbPath,
            serial: serial,
            arguments: ["shell", "am", "start", "-a", "android.intent.action.VIEW_DOWNLOADS"]
        )
    }
}
