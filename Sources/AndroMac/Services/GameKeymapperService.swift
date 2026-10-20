import Foundation
import AppKit
import GameController

public final class GameKeymapperService: @unchecked Sendable {
    public static let shared = GameKeymapperService()

    public private(set) var activeProfile: KeymapProfile
    public private(set) var isKeymapperEnabled: Bool = false
    public private(set) var connectedControllers: [String] = []

    private var keyMonitor: Any?
    private let queue = DispatchQueue(label: "com.andromac.keymapper")

    public var onControllerChanged: (@Sendable () -> Void)?
    public var onKeyTriggered: (@Sendable (String, String) -> Void)?

    private init() {
        self.activeProfile = KeymapProfile.presets.first ?? KeymapProfile(name: "Default", description: "Default Profile", mappings: [])
        setupControllerObservers()
        refreshControllers()
    }

    public func setProfile(_ profile: KeymapProfile) {
        self.activeProfile = profile
    }

    public func setEnabled(_ enabled: Bool, adbPath: String?, serial: String?, resolutionWidth: Int = 2560, resolutionHeight: Int = 1600) {
        self.isKeymapperEnabled = enabled
        if enabled {
            startListening(adbPath: adbPath, serial: serial, width: resolutionWidth, height: resolutionHeight)
        } else {
            stopListening()
        }
    }

    private func setupControllerObservers() {
        NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] _ in
            self?.refreshControllers()
        }
        NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            self?.refreshControllers()
        }
    }

    public func refreshControllers() {
        let names = GCController.controllers().compactMap { $0.vendorName }
        self.connectedControllers = names
        onControllerChanged?()
    }

    public func setupGamepadInputForwarding(adbPath: String, serial: String) {
        for controller in GCController.controllers() {
            if let gamepad = controller.extendedGamepad {
                gamepad.buttonA.valueChangedHandler = { [weak self] _, _, pressed in
                    if pressed { self?.sendKeycode(96, label: "Button A", adbPath: adbPath, serial: serial) }
                }
                gamepad.buttonB.valueChangedHandler = { [weak self] _, _, pressed in
                    if pressed { self?.sendKeycode(97, label: "Button B", adbPath: adbPath, serial: serial) }
                }
                gamepad.buttonX.valueChangedHandler = { [weak self] _, _, pressed in
                    if pressed { self?.sendKeycode(99, label: "Button X", adbPath: adbPath, serial: serial) }
                }
                gamepad.buttonY.valueChangedHandler = { [weak self] _, _, pressed in
                    if pressed { self?.sendKeycode(100, label: "Button Y", adbPath: adbPath, serial: serial) }
                }
                gamepad.dpad.up.valueChangedHandler = { [weak self] _, _, pressed in
                    if pressed { self?.sendKeycode(19, label: "DPad Up", adbPath: adbPath, serial: serial) }
                }
                gamepad.dpad.down.valueChangedHandler = { [weak self] _, _, pressed in
                    if pressed { self?.sendKeycode(20, label: "DPad Down", adbPath: adbPath, serial: serial) }
                }
                gamepad.dpad.left.valueChangedHandler = { [weak self] _, _, pressed in
                    if pressed { self?.sendKeycode(21, label: "DPad Left", adbPath: adbPath, serial: serial) }
                }
                gamepad.dpad.right.valueChangedHandler = { [weak self] _, _, pressed in
                    if pressed { self?.sendKeycode(22, label: "DPad Right", adbPath: adbPath, serial: serial) }
                }
            }
        }
    }

    public func handleDirectKeyInput(key: String, adbPath: String, serial: String, width: Int, height: Int) {
        guard let mapping = activeProfile.mappings.first(where: { $0.key.lowercased() == key.lowercased() }) else {
            return
        }
        triggerMapping(mapping, adbPath: adbPath, serial: serial, width: width, height: height)
    }

    private func triggerMapping(_ mapping: KeyMapping, adbPath: String, serial: String, width: Int, height: Int) {
        Task {
            switch mapping.actionType {
            case .tapCoordinate:
                let x = Int(Double(width) * mapping.xPercent)
                let y = Int(Double(height) * mapping.yPercent)
                _ = try? await ADBService.shared.executeCommand(
                    adbPath: adbPath,
                    serial: serial,
                    arguments: ["shell", "input", "tap", "\(x)", "\(y)"]
                )
                self.onKeyTriggered?(mapping.key, "Tap at (\(x), \(y)) - \(mapping.label)")

            case .swipeDirection:
                let x1 = Int(Double(width) * mapping.xPercent)
                let y1 = Int(Double(height) * mapping.yPercent)
                let x2 = Int(Double(width) * mapping.swipeEndX)
                let y2 = Int(Double(height) * mapping.swipeEndY)
                _ = try? await ADBService.shared.executeCommand(
                    adbPath: adbPath,
                    serial: serial,
                    arguments: ["shell", "input", "swipe", "\(x1)", "\(y1)", "\(x2)", "\(y2)", "120"]
                )
                self.onKeyTriggered?(mapping.key, "Swipe (\(x1),\(y1) ➔ \(x2),\(y2)) - \(mapping.label)")

            case .androidKeycode:
                _ = try? await ADBService.shared.executeCommand(
                    adbPath: adbPath,
                    serial: serial,
                    arguments: ["shell", "input", "keyevent", "\(mapping.androidKeycode)"]
                )
                self.onKeyTriggered?(mapping.key, "Keycode \(mapping.androidKeycode) - \(mapping.label)")
            }
        }
    }

    private func sendKeycode(_ code: Int, label: String, adbPath: String, serial: String) {
        Task {
            _ = try? await ADBService.shared.executeCommand(
                adbPath: adbPath,
                serial: serial,
                arguments: ["shell", "input", "keyevent", "\(code)"]
            )
            self.onKeyTriggered?("Controller", "\(label) (Keycode \(code))")
        }
    }

    private func startListening(adbPath: String?, serial: String?, width: Int, height: Int) {
        guard keyMonitor == nil, let adb = adbPath, let s = serial else { return }

        setupGamepadInputForwarding(adbPath: adb, serial: s)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isKeymapperEnabled else { return event }

            // If user is typing in a text field, don't intercept
            let isTextInputFocused = DispatchQueue.main.sync {
                if let responder = NSApp.keyWindow?.firstResponder {
                    return responder is NSTextView || responder is NSTextField
                }
                return false
            }
            if isTextInputFocused {
                return event
            }

            let keyStr: String
            switch event.keyCode {
            case 49: keyStr = "Space"
            case 36: keyStr = "Return"
            case 53: keyStr = "Escape"
            case 126: keyStr = "↑"
            case 125: keyStr = "↓"
            case 123: keyStr = "←"
            case 124: keyStr = "→"
            default:
                keyStr = event.charactersIgnoringModifiers?.uppercased() ?? ""
            }

            if let mapping = self.activeProfile.mappings.first(where: { $0.key.uppercased() == keyStr }) {
                self.triggerMapping(mapping, adbPath: adb, serial: s, width: width, height: height)
                return nil // Intercept event so it doesn't beep or trigger other shortcuts
            }

            return event
        }
    }

    private func stopListening() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}
