import Foundation

public final class EmulatorProcessManager: @unchecked Sendable {
    public static let shared = EmulatorProcessManager()

    private var activeProcess: Process?
    private var activePID: pid_t?
    private var logBuffer: [String] = []
    private let logQueue = DispatchQueue(label: "com.andromac.logqueue")
    private let maxLogLines = 500

    public private(set) var activeSerial: String?

    private init() {}

    public var isProcessRunning: Bool {
        guard let proc = activeProcess else { return false }
        return proc.isRunning
    }

    public var processID: pid_t? {
        return activePID
    }

    public func getRecentLogs() -> [String] {
        return logQueue.sync { logBuffer }
    }

    public func appendLog(_ message: String) {
        logQueue.async {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            self.logBuffer.append("[\(timestamp)] \(message)")
            if self.logBuffer.count > self.maxLogLines {
                self.logBuffer.removeFirst(self.logBuffer.count - self.maxLogLines)
            }
        }
    }

    public func startEmulator(
        emulatorPath: String,
        adbPath: String,
        config: TabletConfig,
        onStateChange: @escaping @MainActor (EmulatorState) -> Void
    ) async throws {
        if isProcessRunning {
            throw NSError(domain: "EmulatorProcessManager", code: 101, userInfo: [NSLocalizedDescriptionKey: "An Android Emulator process is already running."])
        }

        cleanupStaleInstances(avdName: config.avdName)

        await MainActor.run { onStateChange(.starting("Initializing QEMU Hypervisor...")) }
        appendLog("Starting Android Tablet AVD: \(config.avdName)...")

        let process = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()

        var arguments: [String] = [
            "-avd", config.avdName,
            "-gpu", "host",
            "-use-keycode-forwarding",
            "-camera-back", "none",
            "-camera-front", "none",
            "-memory", "\(config.ramMB)",
            "-cores", "\(config.cpuCores)"
        ]

        if !config.bootAnim {
            arguments.append("-no-boot-anim")
        }

        if config.coldBoot {
            arguments.append("-no-snapshot-load")
        }

        process.executableURL = URL(fileURLWithPath: emulatorPath)
        process.arguments = arguments
        process.standardOutput = outPipe
        process.standardError = errPipe

        let outHandle = outPipe.fileHandleForReading
        let errHandle = errPipe.fileHandleForReading

        outHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                self?.appendLog("EMU_OUT: \(str.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }

        errHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                self?.appendLog("EMU_ERR: \(str.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }

        process.terminationHandler = { [weak self] proc in
            self?.appendLog("Emulator process terminated with status \(proc.terminationStatus)")
            if let serial = self?.activeSerial {
                ADBService.shared.clearMetricsCache(for: serial)
            }
            self?.activeProcess = nil
            self?.activePID = nil
            self?.activeSerial = nil
            Task { @MainActor in
                onStateChange(.stopped)
            }
        }

        try process.run()
        self.activeProcess = process
        self.activePID = process.processIdentifier
        appendLog("Emulator process spawned with PID: \(process.processIdentifier)")

        await MainActor.run { onStateChange(.booting("Waiting for Android OS to initialize...")) }

        let serial = try await waitForDeviceAndBoot(adbPath: adbPath, onProgress: { progress in
            Task { @MainActor in
                onStateChange(.booting(progress))
            }
        })

        self.activeSerial = serial
        appendLog("Device fully booted: \(serial)")

        if config.deviceMode == .laptop || config.enableDesktopMode || config.enableFreeformWindows {
            appendLog("Configuring Android Laptop/Desktop Mode (Freeform multi-windowing & resizable activities)...")
            try? await ADBService.shared.applyDesktopMode(adbPath: adbPath, serial: serial, enable: true)
        }

        await MainActor.run { onStateChange(.running) }
    }

    private func waitForDeviceAndBoot(
        adbPath: String,
        timeoutSeconds: TimeInterval = 120,
        onProgress: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        let startTime = Date()
        var detectedSerial: String?

        while Date().timeIntervalSince(startTime) < timeoutSeconds {
            guard isProcessRunning else {
                throw NSError(domain: "EmulatorProcessManager", code: 102, userInfo: [NSLocalizedDescriptionKey: "Emulator process exited unexpectedly during boot."])
            }

            if detectedSerial == nil {
                let devices = await ADBService.shared.listDevices(adbPath: adbPath)
                if let dev = devices.first {
                    detectedSerial = dev
                    appendLog("Detected ADB device serial: \(dev)")
                    onProgress("Device detected (\(dev)). Checking boot state...")
                }
            }

            if let serial = detectedSerial {
                let bootCompleted = await ADBService.shared.isBootCompleted(adbPath: adbPath, serial: serial)
                if bootCompleted {
                    return serial
                } else {
                    let elapsed = Int(Date().timeIntervalSince(startTime))
                    onProgress("Loading system services (\(elapsed)s)...")
                }
            }

            try await Task.sleep(nanoseconds: 2_000_000_000)
        }

        throw NSError(domain: "EmulatorProcessManager", code: 103, userInfo: [NSLocalizedDescriptionKey: "Boot timeout exceeded (\(Int(timeoutSeconds))s). Android is taking unusually long to boot."])
    }

    public func stopEmulator(adbPath: String) async {
        appendLog("Stopping Android Tablet emulator...")

        if let serial = activeSerial {
            do {
                appendLog("Sending graceful 'emu kill' via ADB...")
                try await ADBService.shared.killEmulator(adbPath: adbPath, serial: serial)
            } catch {
                appendLog("ADB emu kill failed or timed out: \(error.localizedDescription)")
            }
        }

        let deadline = Date().addingTimeInterval(8)
        while isProcessRunning && Date() < deadline {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        if let proc = activeProcess, proc.isRunning {
            appendLog("Sending SIGTERM to emulator process (PID: \(proc.processIdentifier))...")
            proc.terminate()

            let killDeadline = Date().addingTimeInterval(3)
            while proc.isRunning && Date() < killDeadline {
                try? await Task.sleep(nanoseconds: 300_000_000)
            }

            if proc.isRunning {
                appendLog("Force killing process (SIGKILL)...")
                kill(proc.processIdentifier, SIGKILL)
            }
        }

        activeProcess = nil
        activePID = nil
        activeSerial = nil
        appendLog("Emulator stopped.")
    }

    public func cleanupStaleInstances(avdName: String) {
        let script = "ps -ef | grep -i 'qemu-system-aarch64.*\(avdName)' | grep -v grep | awk '{print $2}'"
        let proc = Process()
        let pipe = Pipe()
        proc.executableURL = URL(fileURLWithPath: "/bin/sh")
        proc.arguments = ["-c", script]
        proc.standardOutput = pipe

        try? proc.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()

        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
            let pids = output.split(separator: "\n").compactMap { Int32($0.trimmingCharacters(in: .whitespaces)) }
            for p in pids {
                appendLog("Cleaning up stale emulator process PID: \(p)")
                kill(p, SIGTERM)
            }
        }
    }

    public func getProcessResourceUsage() -> (cpu: Double, memMB: Int) {
        guard let pid = activePID else { return (0.0, 0) }

        let proc = Process()
        let pipe = Pipe()
        proc.executableURL = URL(fileURLWithPath: "/bin/ps")
        proc.arguments = ["-o", "%cpu,rss", "-p", "\(pid)"]
        proc.standardOutput = pipe

        do {
            try proc.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()

            guard let output = String(data: data, encoding: .utf8) else { return (0.0, 0) }
            let lines = output.components(separatedBy: .newlines)
            if lines.count > 1 {
                let parts = lines[1].split(separator: " ", omittingEmptySubsequences: true)
                if parts.count >= 2,
                   let cpu = Double(parts[0]),
                   let rssKB = Int(parts[1]) {
                    return (cpu, rssKB / 1024)
                }
            }
        } catch {
            return (0.0, 0)
        }
        return (0.0, 0)
    }
}
