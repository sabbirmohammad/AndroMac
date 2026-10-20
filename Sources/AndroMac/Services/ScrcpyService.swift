import Foundation
import AppKit

public final class ScrcpyService: @unchecked Sendable {
    public static let shared = ScrcpyService()

    private var activeProcess: Process?
    private let lock = NSLock()

    private init() {}

    public var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let p = activeProcess else { return false }
        return p.isRunning
    }

    public static func findScrcpyBinary() -> String? {
        let candidates = [
            "/opt/homebrew/bin/scrcpy",
            "/usr/local/bin/scrcpy",
            "\(NSHomeDirectory())/.homebrew/bin/scrcpy"
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    public var isAvailable: Bool {
        return ScrcpyService.findScrcpyBinary() != nil
    }

    public func hideRawEmulatorWindow() {
        DispatchQueue.main.async {
            let apps = NSWorkspace.shared.runningApplications
            for app in apps {
                let name = app.localizedName?.lowercased() ?? ""
                if name.contains("qemu") || name.contains("emulator") {
                    app.hide()
                }
            }
        }
    }

    public func startSession(
        adbPath: String,
        serial: String,
        title: String = "AndroMac",
        fullscreen: Bool = false,
        maxSize: Int = 1600,
        maxFps: Int = 60,
        videoBuffer: Int = 15
    ) throws {
        lock.lock()
        defer { lock.unlock() }

        if let proc = activeProcess, proc.isRunning {
            proc.terminate()
            activeProcess = nil
        }

        guard let binary = ScrcpyService.findScrcpyBinary() else {
            throw NSError(
                domain: "ScrcpyService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "scrcpy binary not found. Please install scrcpy via Homebrew."]
            )
        }

        let adbDir = (adbPath as NSString).deletingLastPathComponent
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)

        var env = ProcessInfo.processInfo.environment
        let existingPath = env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = "\(adbDir):/opt/homebrew/bin:/usr/local/bin:\(existingPath)"
        process.environment = env

        var args = [
            "-s", serial,
            "--window-title", title,
            "--stay-awake",
            "--no-audio",
            "--max-size", "\(maxSize)",
            "--max-fps", "\(maxFps)",
            "--video-bit-rate", "8M",
            "--video-buffer", "\(videoBuffer)",
            "--video-codec", "h264"
        ]

        if fullscreen {
            args.append("--fullscreen")
        }

        process.arguments = args
        try process.run()
        self.activeProcess = process

        // Hide the cluttered QEMU window so only the pure scrcpy window is seen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.hideRawEmulatorWindow()
            let apps = NSWorkspace.shared.runningApplications
            if let scrcpyApp = apps.first(where: {
                let name = $0.localizedName?.lowercased() ?? ""
                let bundle = $0.bundleIdentifier?.lowercased() ?? ""
                return name.contains("scrcpy") || bundle.contains("scrcpy")
            }) {
                scrcpyApp.activate(options: [])
            }
        }
    }

    public func stopSession() {
        lock.lock()
        defer { lock.unlock() }
        if let proc = activeProcess, proc.isRunning {
            proc.terminate()
        }
        activeProcess = nil
    }
}
