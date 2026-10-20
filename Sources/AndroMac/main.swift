import SwiftUI
import AppKit

@main
struct AndroMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Android") {
                Button("Start Android Tablet") {
                    NotificationCenter.default.post(name: .startAndroidTablet, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Stop Android Tablet") {
                    NotificationCenter.default.post(name: .stopAndroidTablet, object: nil)
                }
                .keyboardShortcut(".", modifiers: [.command])

                Divider()

                Button("Toggle Full-Screen") {
                    FullScreenCoordinator.shared.toggleFullScreen()
                }
                .keyboardShortcut("f", modifiers: [.control, .command])
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up emulator processes if still active
        if let adb = EnvironmentDetector.shared.detect().adbPath {
            let sema = DispatchSemaphore(value: 0)
            Task {
                await EmulatorProcessManager.shared.stopEmulator(adbPath: adb)
                sema.signal()
            }
            _ = sema.wait(timeout: .now() + 3.0)
        }
    }
}

extension Notification.Name {
    static let startAndroidTablet = Notification.Name("AndroMac.StartAndroidTablet")
    static let stopAndroidTablet = Notification.Name("AndroMac.StopAndroidTablet")
}
