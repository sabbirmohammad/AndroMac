import Foundation
import AppKit

public final class ADBService: Sendable {
    public static let shared = ADBService()

    private init() {}

    public func executeCommand(adbPath: String, serial: String? = nil, arguments: [String]) async throws -> String {
        let process = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()

        var fullArgs: [String] = []
        if let s = serial, !s.isEmpty {
            fullArgs.append(contentsOf: ["-s", s])
        }
        fullArgs.append(contentsOf: arguments)

        process.executableURL = URL(fileURLWithPath: adbPath)
        process.arguments = fullArgs
        process.standardOutput = pipe
        process.standardError = errorPipe

        return try await withCheckedThrowingContinuation { continuation in
            do {
                process.terminationHandler = { proc in
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    let errOutput = String(data: errData, encoding: .utf8) ?? ""

                    if proc.terminationStatus == 0 {
                        continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
                    } else {
                        let msg = errOutput.isEmpty ? output : errOutput
                        continuation.resume(throwing: NSError(domain: "ADBService", code: Int(proc.terminationStatus), userInfo: [NSLocalizedDescriptionKey: msg.trimmingCharacters(in: .whitespacesAndNewlines)]))
                    }
                }
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public func listDevices(adbPath: String) async -> [String] {
        guard let output = try? await executeCommand(adbPath: adbPath, arguments: ["devices"]) else {
            return []
        }
        let lines = output.components(separatedBy: .newlines)
        var devices: [String] = []
        for line in lines.dropFirst() {
            let parts = line.split(separator: "\t")
            if parts.count >= 2 && parts[1].trimmingCharacters(in: .whitespaces) == "device" {
                devices.append(String(parts[0]))
            }
        }
        return devices
    }

    public func isBootCompleted(adbPath: String, serial: String) async -> Bool {
        do {
            let result = try await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "getprop", "sys.boot_completed"])
            return result.trimmingCharacters(in: .whitespacesAndNewlines) == "1"
        } catch {
            return false
        }
    }

    public func getMetrics(adbPath: String, serial: String) async -> DeviceMetrics {
        var metrics = DeviceMetrics()
        metrics.activeSerial = serial

        if let model = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "getprop", "ro.product.model"]) {
            metrics.model = model
        }

        if let ver = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "getprop", "ro.build.version.release"]) {
            metrics.androidVersion = ver
        }

        if let apiStr = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "getprop", "ro.build.version.sdk"]),
           let api = Int(apiStr) {
            metrics.apiLevel = api
        }

        if let size = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "wm", "size"]) {
            let comps = size.components(separatedBy: ":")
            if comps.count > 1 {
                metrics.resolution = comps[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        if let dens = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "wm", "density"]) {
            let comps = dens.components(separatedBy: ":")
            if comps.count > 1, let d = Int(comps[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
                metrics.density = d
            }
        }

        if let packages = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "pm", "list", "packages", "com.android.vending"]) {
            metrics.isPlayStoreAvailable = packages.contains("com.android.vending")
        }

        if let uptime = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "uptime"]) {
            metrics.uptime = uptime
        }

        return metrics
    }

    public func sendKeyEvent(adbPath: String, serial: String, keyCode: Int) async throws {
        _ = try await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "input", "keyevent", "\(keyCode)"])
    }

    public func sendBack(adbPath: String, serial: String) async throws {
        try await sendKeyEvent(adbPath: adbPath, serial: serial, keyCode: 4)
    }

    public func sendHome(adbPath: String, serial: String) async throws {
        try await sendKeyEvent(adbPath: adbPath, serial: serial, keyCode: 3)
    }

    public func sendRecents(adbPath: String, serial: String) async throws {
        try await sendKeyEvent(adbPath: adbPath, serial: serial, keyCode: 187)
    }

    public func sendVolumeUp(adbPath: String, serial: String) async throws {
        try await sendKeyEvent(adbPath: adbPath, serial: serial, keyCode: 24)
    }

    public func sendVolumeDown(adbPath: String, serial: String) async throws {
        try await sendKeyEvent(adbPath: adbPath, serial: serial, keyCode: 25)
    }

    public func expandNotifications(adbPath: String, serial: String) async throws {
        _ = try await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "cmd", "statusbar", "expand-notifications"])
    }

    public func expandQuickSettings(adbPath: String, serial: String) async throws {
        _ = try await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "cmd", "statusbar", "expand-settings"])
    }

    public func setOrientation(adbPath: String, serial: String, landscape: Bool) async throws {
        let rotationValue = landscape ? "1" : "0"
        _ = try await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "settings", "put", "system", "accelerometer_rotation", "0"])
        _ = try await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "settings", "put", "system", "user_rotation", rotationValue])
    }

    public func sendTextInput(adbPath: String, serial: String, text: String) async throws {
        let safeText = text.replacingOccurrences(of: " ", with: "%s")
        _ = try await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "input", "text", safeText])
    }

    public func openPlayStore(adbPath: String, serial: String) async throws {
        _ = try await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "am", "start", "-a", "android.intent.action.MAIN", "-c", "android.intent.category.APP_MARKET"])
    }

    public func killEmulator(adbPath: String, serial: String) async throws {
        _ = try await executeCommand(adbPath: adbPath, serial: serial, arguments: ["emu", "kill"])
    }

    public func captureScreenshot(adbPath: String, serial: String) async -> NSImage? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: adbPath)
        process.arguments = ["-s", serial, "exec-out", "screencap", "-p"]
        process.standardOutput = pipe

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            if process.terminationStatus == 0, !data.isEmpty {
                return NSImage(data: data)
            }
        } catch {
            return nil
        }
        return nil
    }

    public func listInstalledPackages(adbPath: String, serial: String) async -> [InstalledApp] {
        guard let output = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "pm", "list", "packages", "-3"]) else {
            return []
        }
        let lines = output.components(separatedBy: .newlines)
        return lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("package:") else { return nil }
            let pkg = String(trimmed.dropFirst("package:".count))
            let displayName = pkg.components(separatedBy: ".").last?.capitalized ?? pkg
            return InstalledApp(packageName: pkg, label: displayName, isSystemApp: false)
        }
    }

    public func launchApp(adbPath: String, serial: String, packageName: String) async throws {
        _ = try await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "monkey", "-p", packageName, "-c", "android.intent.category.LAUNCHER", "1"])
    }

    public func uninstallApp(adbPath: String, serial: String, packageName: String) async throws {
        _ = try await executeCommand(adbPath: adbPath, serial: serial, arguments: ["uninstall", packageName])
    }
}
