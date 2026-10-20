import Foundation
import AppKit

private final class MetricsCache: @unchecked Sendable {
    private var cache: [String: DeviceMetrics] = [:]
    private let lock = NSLock()

    func get(for serial: String) -> DeviceMetrics? {
        lock.lock()
        defer { lock.unlock() }
        return cache[serial]
    }

    func set(_ metrics: DeviceMetrics, for serial: String) {
        lock.lock()
        defer { lock.unlock() }
        cache[serial] = metrics
    }

    func clear(for serial: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        if let s = serial {
            cache.removeValue(forKey: s)
        } else {
            cache.removeAll()
        }
    }
}

private final class ScreenshotLock: @unchecked Sendable {
    private var isBusy = false
    private let lock = NSLock()

    func tryAcquire() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if isBusy { return false }
        isBusy = true
        return true
    }

    func release() {
        lock.lock()
        defer { lock.unlock() }
        isBusy = false
    }
}

public final class ADBService: Sendable {
    public static let shared = ADBService()

    private let metricsCache = MetricsCache()
    private let screenshotLock = ScreenshotLock()

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

    public func clearMetricsCache(for serial: String? = nil) {
        metricsCache.clear(for: serial)
    }

    public func getMetrics(adbPath: String, serial: String, forceRefresh: Bool = false) async -> DeviceMetrics {
        var metrics = metricsCache.get(for: serial) ?? DeviceMetrics()
        metrics.activeSerial = serial

        // Batch fetch static properties if not yet cached or if forceRefresh is requested
        let needsStaticFetch = forceRefresh || metrics.model.isEmpty || metrics.resolution.isEmpty
        if needsStaticFetch {
            let batchScript = "getprop ro.product.model; echo '---SEP---'; getprop ro.build.version.release; echo '---SEP---'; getprop ro.build.version.sdk; echo '---SEP---'; wm size; echo '---SEP---'; wm density; echo '---SEP---'; pm list packages com.android.vending"
            if let output = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", batchScript]) {
                let sections = output.components(separatedBy: "---SEP---").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                if sections.count >= 6 {
                    metrics.model = sections[0].isEmpty ? "Pixel Tablet" : sections[0]
                    metrics.androidVersion = sections[1].isEmpty ? "16" : sections[1]
                    metrics.apiLevel = Int(sections[2]) ?? 36
                    let sizeComps = sections[3].components(separatedBy: ":")
                    if sizeComps.count > 1 {
                        metrics.resolution = sizeComps[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    let densComps = sections[4].components(separatedBy: ":")
                    if densComps.count > 1, let d = Int(densComps[1].trimmingCharacters(in: .whitespacesAndNewlines)) {
                        metrics.density = d
                    }
                    metrics.isPlayStoreAvailable = sections[5].contains("com.android.vending")
                }
            }
            metricsCache.set(metrics, for: serial)
        }

        // Only query uptime dynamically (single lightweight call)
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
        guard screenshotLock.tryAcquire() else {
            return nil
        }
        defer { screenshotLock.release() }

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

    public func launchAppInFreeform(adbPath: String, serial: String, packageName: String) async throws {
        // Launch app explicitly in freeform windowing mode (Windowing mode 5 = WINDOWING_MODE_FREEFORM)
        do {
            _ = try await executeCommand(adbPath: adbPath, serial: serial, arguments: [
                "shell", "am", "start", "--windowingMode", "5",
                "-a", "android.intent.action.MAIN",
                "-c", "android.intent.category.LAUNCHER",
                "-p", packageName
            ])
        } catch {
            // Fallback to standard launcher if windowingMode flag is rejected by older shell
            try await launchApp(adbPath: adbPath, serial: serial, packageName: packageName)
        }
    }

    public func applyDesktopMode(adbPath: String, serial: String, enable: Bool) async throws {
        let val = enable ? "1" : "0"
        // 1. Freeform window management support
        _ = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "settings", "put", "global", "enable_freeform_support", val])
        // 2. Force all apps to be resizable in freeform/multi-window
        _ = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "settings", "put", "global", "force_resizable_activities", val])
        // 3. Android Desktop Mode properties (Android 10 - 16)
        _ = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "setprop", "persist.wm.debug.desktop_mode", val])
        _ = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "setprop", "persist.wm.debug.desktop_mode_compat_ui", val])
        // 4. Secure freeform window management
        _ = try? await executeCommand(adbPath: adbPath, serial: serial, arguments: ["shell", "settings", "put", "secure", "freeform_window_management", val])
    }

    public func uninstallApp(adbPath: String, serial: String, packageName: String) async throws {
        _ = try await executeCommand(adbPath: adbPath, serial: serial, arguments: ["uninstall", packageName])
    }
}
