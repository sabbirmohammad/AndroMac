import Foundation
import AppKit

public final class FullScreenCoordinator: Sendable {
    public static let shared = FullScreenCoordinator()

    private init() {}

    public func focusEmulatorWindow() {
        DispatchQueue.main.async {
            let apps = NSWorkspace.shared.runningApplications
            if let scrcpyApp = apps.first(where: {
                let name = $0.localizedName?.lowercased() ?? ""
                return name.contains("scrcpy")
            }) {
                scrcpyApp.activate(options: [.activateIgnoringOtherApps])
                return
            }
            if let emuApp = apps.first(where: {
                let name = $0.localizedName?.lowercased() ?? ""
                let bundle = $0.bundleIdentifier?.lowercased() ?? ""
                return name.contains("qemu") || name.contains("emulator") || bundle.contains("android")
            }) {
                emuApp.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }

    public func focusLauncherWindow() {
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let window = NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    public func toggleFullScreen() {
        focusEmulatorWindow()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let src = CGEventSource(stateID: .hidSystemState)
            let keyCode: CGKeyCode = 0x03 // 'f'
            let flags: CGEventFlags = [.maskCommand, .maskControl]

            if let keyDown = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true),
               let keyUp = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false) {
                keyDown.flags = flags
                keyUp.flags = flags
                keyDown.post(tap: .cghidEventTap)
                keyUp.post(tap: .cghidEventTap)
            }
        }
    }
}
