import Foundation
import AppKit

public final class ClipboardSyncService: @unchecked Sendable {
    public static let shared = ClipboardSyncService()

    private var syncTimer: Timer?
    private var lastMacChangeCount: Int = -1
    private var lastAndroidText: String = ""
    private var lastMacText: String = ""
    private var isSyncing: Bool = false

    public private(set) var isRunning: Bool = false
    public var onSyncEvent: (@Sendable (String) -> Void)?

    private init() {}

    public func startSync(adbPath: String, serial: String) {
        guard !isRunning else { return }
        isRunning = true
        lastMacChangeCount = NSPasteboard.general.changeCount

        DispatchQueue.main.async { [weak self] in
            self?.syncTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                Task {
                    await self.performSyncCycle(adbPath: adbPath, serial: serial)
                }
            }
        }
    }

    public func stopSync() {
        isRunning = false
        DispatchQueue.main.async { [weak self] in
            self?.syncTimer?.invalidate()
            self?.syncTimer = nil
        }
    }

    public func performSyncCycle(adbPath: String, serial: String) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let currentChangeCount = await MainActor.run { NSPasteboard.general.changeCount }

        // Check if Mac clipboard changed
        if currentChangeCount != lastMacChangeCount {
            lastMacChangeCount = currentChangeCount
            if let macString = await MainActor.run(body: { NSPasteboard.general.string(forType: .string) }),
               !macString.isEmpty, macString != lastAndroidText {
                lastMacText = macString
                let success = await setAndroidClipboard(adbPath: adbPath, serial: serial, text: macString)
                if success {
                    lastAndroidText = macString
                    let preview = macString.prefix(30).replacingOccurrences(of: "\n", with: " ")
                    onSyncEvent?("Mac ➔ Android: \"\(preview)\(macString.count > 30 ? "..." : "")\"")
                }
                return
            }
        }

        // Check if Android clipboard changed
        if let androidText = await getAndroidClipboard(adbPath: adbPath, serial: serial),
           !androidText.isEmpty, androidText != lastAndroidText, androidText != lastMacText {
            lastAndroidText = androidText
            lastMacText = androidText
            await MainActor.run {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(androidText, forType: .string)
                self.lastMacChangeCount = NSPasteboard.general.changeCount
            }
            let preview = androidText.prefix(30).replacingOccurrences(of: "\n", with: " ")
            onSyncEvent?("Android ➔ Mac: \"\(preview)\(androidText.count > 30 ? "..." : "")\"")
        }
    }

    public func pushMacClipboard(adbPath: String, serial: String) async -> Bool {
        guard let macString = await MainActor.run(body: { NSPasteboard.general.string(forType: .string) }), !macString.isEmpty else {
            return false
        }
        let success = await setAndroidClipboard(adbPath: adbPath, serial: serial, text: macString)
        if success {
            lastAndroidText = macString
            lastMacText = macString
            onSyncEvent?("Manual Push: Mac ➔ Android")
        }
        return success
    }

    public func pullAndroidClipboard(adbPath: String, serial: String) async -> String? {
        guard let androidText = await getAndroidClipboard(adbPath: adbPath, serial: serial), !androidText.isEmpty else {
            return nil
        }
        lastAndroidText = androidText
        lastMacText = androidText
        await MainActor.run {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(androidText, forType: .string)
            self.lastMacChangeCount = NSPasteboard.general.changeCount
        }
        onSyncEvent?("Manual Pull: Android ➔ Mac")
        return androidText
    }

    public func getAndroidClipboard(adbPath: String, serial: String) async -> String? {
        if let output = try? await ADBService.shared.executeCommand(
            adbPath: adbPath,
            serial: serial,
            arguments: ["shell", "settings", "get", "global", "andromac_clipboard"]
        ) {
            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed != "null" {
                return trimmed
            }
        }
        return nil
    }

    public func setAndroidClipboard(adbPath: String, serial: String, text: String) async -> Bool {
        // Save in global settings for retrieval and cross-system sync
        _ = try? await ADBService.shared.executeCommand(
            adbPath: adbPath,
            serial: serial,
            arguments: ["shell", "settings", "put", "global", "andromac_clipboard", text]
        )
        // Forward text to the active Android focused field
        return (try? await ADBService.shared.sendTextInput(adbPath: adbPath, serial: serial, text: text)) != nil
    }
}
