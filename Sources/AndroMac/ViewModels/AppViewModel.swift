import Foundation
import SwiftUI
import AppKit

public enum NavigationTab: String, CaseIterable, Identifiable, Sendable {
    case dashboard = "Dashboard & Live View"
    case fileSharing = "File Sharing"
    case apkInstaller = "APK & Apps"
    case controls = "Controls & Gestures"
    case gameKeymapper = "Game Keymapper"
    case snapshots = "Snapshots & Backup"
    case instances = "Instance Manager"
    case displaySettings = "Tablet Settings"
    case setupWizard = "Setup Wizard"
    case logs = "Logs & Diagnostics"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .dashboard: return "ipad.landscape"
        case .fileSharing: return "folder.fill"
        case .apkInstaller: return "arrow.down.doc.fill"
        case .controls: return "dpad.fill"
        case .gameKeymapper: return "gamecontroller.fill"
        case .snapshots: return "camera.fill"
        case .instances: return "square.stack.3d.up.fill"
        case .displaySettings: return "slider.horizontal.3"
        case .setupWizard: return "wand.and.stars"
        case .logs: return "terminal.fill"
        }
    }
}

@MainActor
public final class AppViewModel: ObservableObject {
    @Published public var state: EmulatorState = .stopped
    @Published public var report: EnvironmentReport
    @Published public var config: TabletConfig
    @Published public var metrics: DeviceMetrics = .placeholder
    @Published public var installedApps: [InstalledApp] = []
    @Published public var screenPreview: NSImage?
    @Published public var logs: [String] = []
    @Published public var selectedTab: NavigationTab = .dashboard
    @Published public var isInstallingAPK: Bool = false
    @Published public var apkInstallResult: APKInstallResult?
    @Published public var alertMessage: String?
    @Published public var showAlert: Bool = false

    // UI state bindings
    @Published public var isTargeted: Bool = false
    @Published public var showFilePicker: Bool = false
    @Published public var customTextInput: String = ""
    @Published public var showWipeConfirm: Bool = false
    @Published public var filterQuery: String = ""

    // 1. Bidirectional Clipboard Sync
    @Published public var isClipboardSyncEnabled: Bool = true
    @Published public var lastClipboardEvent: String = "Ready (Bidirectional active)"

    // 2. File & Media Sharing
    @Published public var sharedFiles: [AndroidFileItem] = []
    @Published public var isTransferringFile: Bool = false
    @Published public var fileTransferStatus: String? = nil
    @Published public var isFileDropTargeted: Bool = false

    // 3. Game Keymapper
    @Published public var isKeymapperActive: Bool = false
    @Published public var activeKeymapProfile: KeymapProfile
    @Published public var availableProfiles: [KeymapProfile] = KeymapProfile.presets
    @Published public var connectedGamepads: [String] = []
    @Published public var lastKeymapAction: String = "Ready for key or controller input"
    @Published public var newKeymapInputKey: String = ""
    @Published public var newKeymapLabel: String = ""
    @Published public var newKeymapActionType: KeyActionType = .tapCoordinate
    @Published public var newKeymapXPercent: Double = 0.5
    @Published public var newKeymapYPercent: Double = 0.5
    @Published public var newKeymapCode: Int = 19

    // 4. Snapshots & Instant Backup
    @Published public var snapshots: [EmulatorSnapshot] = []
    @Published public var isSnapshotLoading: Bool = false
    @Published public var showCreateSnapshotSheet: Bool = false
    @Published public var snapshotNameInput: String = ""

    // 5. Multi-Instance Management
    @Published public var instances: [AVDInstance] = []
    @Published public var showCreateInstanceModal: Bool = false
    @Published public var showCloneInstanceModal: Bool = false
    @Published public var selectedInstanceToClone: AVDInstance? = nil
    @Published public var newInstName: String = ""
    @Published public var newInstDisplayName: String = ""
    @Published public var newInstWidth: Int = 2560
    @Published public var newInstHeight: Int = 1600
    @Published public var newInstDensity: Int = 280
    @Published public var newInstRamMB: Int = 3072
    @Published public var newInstCores: Int = 4
    @Published public var newInstStorageGB: Int = 8

    // 6. Live In-App View & Streaming
    @Published public var isLiveStreaming: Bool = false
    @Published public var liveDragStartLocation: CGPoint? = nil
    private var liveStreamTimer: Timer?

    // 7. OTA / Update Checker
    @Published public var updateInfo: AppUpdateInfo? = nil
    @Published public var isCheckingForUpdates: Bool = false

    private var metricsTimer: Timer?

    public init() {
        let rep = EnvironmentDetector.shared.detect()
        self.report = rep
        self.config = TabletConfig.load()
        self.activeKeymapProfile = KeymapProfile.presets.first ?? KeymapProfile(name: "Default", description: "Default", mappings: [])

        if !AVDManager.shared.doesAVDExist(named: config.avdName) && rep.isReadyToRun {
            try? AVDManager.shared.configureAVD(config: config, report: rep)
        }

        refreshLogs()
        refreshSnapshots()
        refreshInstances()
        setupKeymapperCallbacks()
        setupClipboardCallbacks()
    }

    public func refreshEnvironment() {
        self.report = EnvironmentDetector.shared.detect()
        refreshInstances()
    }

    // MARK: - Emulator Lifecycle

    public func startTablet() {
        guard report.isReadyToRun else {
            showAlertMessage("Cannot start: Required Android SDK or ARM64 Google Play image is missing. Please run Setup Wizard.")
            selectedTab = .setupWizard
            return
        }

        guard let emuPath = report.emulatorPath, let adb = report.adbPath else {
            showAlertMessage("Android Emulator or ADB binary path not found.")
            return
        }

        try? AVDManager.shared.configureAVD(config: config, report: report)

        let currentConfig = config
        Task { [weak self] in
            do {
                try await EmulatorProcessManager.shared.startEmulator(
                    emulatorPath: emuPath,
                    adbPath: adb,
                    config: currentConfig
                ) { newState in
                    guard let self = self else { return }
                    self.state = newState
                    if case .running = newState {
                        self.startMetricsPolling()
                        self.refreshMetrics()
                        self.refreshInstalledApps()
                        self.refreshSharedFiles()
                        self.refreshSnapshots()
                        self.refreshInstances()
                        if self.isClipboardSyncEnabled, let s = EmulatorProcessManager.shared.activeSerial {
                            ClipboardSyncService.shared.startSync(adbPath: adb, serial: s)
                        }
                        FullScreenCoordinator.shared.focusEmulatorWindow()
                    } else if case .stopped = newState {
                        self.stopMetricsPolling()
                        self.stopLiveStream()
                        ClipboardSyncService.shared.stopSync()
                        self.refreshInstances()
                    }
                }
            } catch {
                self?.state = .error(error.localizedDescription)
                self?.showAlertMessage("Failed to start emulator: \(error.localizedDescription)")
            }
        }
    }

    public func stopTablet() {
        guard let adb = report.adbPath else { return }
        state = .shuttingDown("Saving state and exiting...")
        stopLiveStream()
        ClipboardSyncService.shared.stopSync()
        Task {
            await EmulatorProcessManager.shared.stopEmulator(adbPath: adb)
            await MainActor.run {
                self.state = .stopped
                self.stopMetricsPolling()
                self.metrics = .placeholder
                self.screenPreview = nil
                self.refreshInstances()
            }
        }
    }

    public func restartTablet() {
        Task {
            stopTablet()
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            startTablet()
        }
    }

    public func toggleFullScreen() {
        FullScreenCoordinator.shared.toggleFullScreen()
    }

    // MARK: - 1. Bidirectional Clipboard Sync

    private func setupClipboardCallbacks() {
        ClipboardSyncService.shared.onSyncEvent = { [weak self] message in
            Task { @MainActor [weak self] in
                self?.lastClipboardEvent = message
                self?.refreshLogs()
            }
        }
    }

    public func toggleClipboardSync(enabled: Bool) {
        isClipboardSyncEnabled = enabled
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial, state.isRunning else { return }
        if enabled {
            ClipboardSyncService.shared.startSync(adbPath: adb, serial: serial)
            lastClipboardEvent = "Auto-sync active (Bidirectional)"
        } else {
            ClipboardSyncService.shared.stopSync()
            lastClipboardEvent = "Auto-sync disabled"
        }
    }

    public func pushClipboardToAndroid() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else {
            showAlertMessage("Tablet must be running to push clipboard.")
            return
        }
        Task {
            let ok = await ClipboardSyncService.shared.pushMacClipboard(adbPath: adb, serial: serial)
            if ok {
                self.lastClipboardEvent = "Manual Push: Mac ➔ Android"
            }
        }
    }

    public func pullClipboardFromAndroid() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else {
            showAlertMessage("Tablet must be running to pull clipboard.")
            return
        }
        Task {
            if let text = await ClipboardSyncService.shared.pullAndroidClipboard(adbPath: adb, serial: serial) {
                self.lastClipboardEvent = "Pulled from Android (\(text.count) chars)"
            } else {
                self.lastClipboardEvent = "Android clipboard is empty"
            }
        }
    }

    // MARK: - 2. File & Media Sharing

    public func refreshSharedFiles() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            let files = await FileTransferService.shared.listFiles(directory: "/sdcard/Download", adbPath: adb, serial: serial)
            await MainActor.run {
                self.sharedFiles = files
            }
        }
    }

    public func uploadFiles(urls: [URL]) {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else {
            showAlertMessage("Tablet is offline. Start the tablet to transfer files.")
            return
        }

        isTransferringFile = true
        fileTransferStatus = "Transferring \(urls.count) file(s)..."

        Task {
            var successCount = 0
            for url in urls {
                do {
                    try await FileTransferService.shared.pushFile(at: url, adbPath: adb, serial: serial)
                    successCount += 1
                } catch {
                    EmulatorProcessManager.shared.appendLog("Failed to push file \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                self.isTransferringFile = false
                self.fileTransferStatus = "\(successCount) file(s) saved to /sdcard/Download"
                self.refreshSharedFiles()
            }
        }
    }

    public func downloadFileToMac(remotePath: String) {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
        let filename = (remotePath as NSString).lastPathComponent
        let targetURL = downloadsURL.appendingPathComponent(filename)

        isTransferringFile = true
        fileTransferStatus = "Saving \(filename) to ~/Downloads..."

        Task {
            do {
                try await FileTransferService.shared.pullFile(remotePath: remotePath, to: targetURL, adbPath: adb, serial: serial)
                await MainActor.run {
                    self.isTransferringFile = false
                    self.fileTransferStatus = "Downloaded \(filename) to ~/Downloads"
                    NSWorkspace.shared.activateFileViewerSelecting([targetURL])
                }
            } catch {
                await MainActor.run {
                    self.isTransferringFile = false
                    self.fileTransferStatus = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }

    public func deleteRemoteFile(remotePath: String) {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            try? await FileTransferService.shared.deleteFile(remotePath: remotePath, adbPath: adb, serial: serial)
            self.refreshSharedFiles()
        }
    }

    public func openAndroidDownloads() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            try? await FileTransferService.shared.openDownloadsFolderInAndroid(adbPath: adb, serial: serial)
            FullScreenCoordinator.shared.focusEmulatorWindow()
        }
    }

    // MARK: - 3. Game Keymapper & Gamepad

    private func setupKeymapperCallbacks() {
        GameKeymapperService.shared.onControllerChanged = { [weak self] in
            Task { @MainActor [weak self] in
                self?.connectedGamepads = GameKeymapperService.shared.connectedControllers
            }
        }
        GameKeymapperService.shared.onKeyTriggered = { [weak self] key, label in
            Task { @MainActor [weak self] in
                self?.lastKeymapAction = "[\(key)] \(label)"
            }
        }
    }

    public func toggleKeymapper(enabled: Bool) {
        isKeymapperActive = enabled
        GameKeymapperService.shared.setProfile(activeKeymapProfile)
        GameKeymapperService.shared.setEnabled(
            enabled,
            adbPath: report.adbPath,
            serial: EmulatorProcessManager.shared.activeSerial,
            resolutionWidth: config.width,
            resolutionHeight: config.height
        )
    }

    public func selectKeymapProfile(_ profile: KeymapProfile) {
        activeKeymapProfile = profile
        GameKeymapperService.shared.setProfile(profile)
    }

    public func deleteKeyMapping(id: UUID) {
        activeKeymapProfile.mappings.removeAll { $0.id == id }
        GameKeymapperService.shared.setProfile(activeKeymapProfile)
    }

    public func addKeyMapping(_ mapping: KeyMapping) {
        activeKeymapProfile.mappings.append(mapping)
        GameKeymapperService.shared.setProfile(activeKeymapProfile)
    }

    // MARK: - 4. Snapshots & Backup

    public func refreshSnapshots() {
        snapshots = SnapshotService.shared.listSnapshots(avdName: config.avdName)
    }

    public func createSnapshot(name: String) {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial, state.isRunning else {
            showAlertMessage("Tablet must be running to take a live snapshot.")
            return
        }

        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        isSnapshotLoading = true
        Task {
            do {
                try await SnapshotService.shared.saveSnapshot(name: cleanName, adbPath: adb, serial: serial)
                await MainActor.run {
                    self.isSnapshotLoading = false
                    self.refreshSnapshots()
                    self.showAlertMessage("Snapshot '\(cleanName)' saved successfully!")
                }
            } catch {
                await MainActor.run {
                    self.isSnapshotLoading = false
                    self.showAlertMessage("Failed to save snapshot: \(error.localizedDescription)")
                }
            }
        }
    }

    public func restoreSnapshot(name: String) {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial, state.isRunning else {
            showAlertMessage("Tablet must be running to restore a snapshot.")
            return
        }

        isSnapshotLoading = true
        Task {
            do {
                try await SnapshotService.shared.loadSnapshot(name: name, adbPath: adb, serial: serial)
                await MainActor.run {
                    self.isSnapshotLoading = false
                    self.captureScreen()
                    self.showAlertMessage("Snapshot '\(name)' restored!")
                }
            } catch {
                await MainActor.run {
                    self.isSnapshotLoading = false
                    self.showAlertMessage("Failed to load snapshot: \(error.localizedDescription)")
                }
            }
        }
    }

    public func deleteSnapshot(name: String) {
        let adb = report.adbPath
        let serial = EmulatorProcessManager.shared.activeSerial
        Task {
            try? await SnapshotService.shared.deleteSnapshot(name: name, adbPath: adb, serial: serial, avdName: config.avdName)
            await MainActor.run {
                self.refreshSnapshots()
            }
        }
    }

    // MARK: - 5. Multi-Instance Management

    public func refreshInstances() {
        instances = InstanceManager.shared.listInstances(
            currentAVDName: config.avdName,
            isEmulatorRunning: state.isRunning
        )
    }

    public func switchToInstance(name: String) {
        guard !state.isRunning else {
            showAlertMessage("Please stop the current tablet before switching instances.")
            return
        }

        config.avdName = name
        config.save()
        refreshInstances()
        showAlertMessage("Switched active device to '\(name)'. Click 'Start Android' to launch it.")
    }

    public func createNewInstance(
        name: String,
        displayName: String,
        width: Int,
        height: Int,
        density: Int,
        ramMB: Int,
        cpuCores: Int,
        storageGB: Int
    ) {
        do {
            try InstanceManager.shared.createInstance(
                name: name,
                displayName: displayName,
                width: width,
                height: height,
                density: density,
                ramMB: ramMB,
                cpuCores: cpuCores,
                storageGB: storageGB,
                report: report
            )
            refreshInstances()
            showAlertMessage("Instance '\(displayName)' created successfully!")
        } catch {
            showAlertMessage("Failed to create instance: \(error.localizedDescription)")
        }
    }

    public func cloneInstance(sourceName: String, targetName: String, targetDisplayName: String) {
        do {
            try InstanceManager.shared.cloneInstance(sourceName: sourceName, targetName: targetName, targetDisplayName: targetDisplayName)
            refreshInstances()
            showAlertMessage("Instance cloned successfully as '\(targetDisplayName)'!")
        } catch {
            showAlertMessage("Failed to clone instance: \(error.localizedDescription)")
        }
    }

    public func deleteInstance(name: String) {
        guard name != config.avdName || !state.isRunning else {
            showAlertMessage("Cannot delete an instance that is currently running.")
            return
        }
        do {
            try InstanceManager.shared.deleteInstance(name: name)
            refreshInstances()
        } catch {
            showAlertMessage("Failed to delete instance: \(error.localizedDescription)")
        }
    }

    // MARK: - 6. Live In-App View & Touch Input

    public func toggleLiveStream(enabled: Bool) {
        isLiveStreaming = enabled
        if enabled {
            startLiveStream()
        } else {
            stopLiveStream()
        }
    }

    private func startLiveStream() {
        liveStreamTimer?.invalidate()
        captureScreen()
        liveStreamTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isLiveStreaming, self.state.isRunning else { return }
                self.captureScreen()
            }
        }
    }

    private func stopLiveStream() {
        liveStreamTimer?.invalidate()
        liveStreamTimer = nil
        isLiveStreaming = false
    }

    public func handleScreenTap(normalizedX: Double, normalizedY: Double) {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial, state.isRunning else { return }
        let x = Int(Double(config.width) * max(0.0, min(1.0, normalizedX)))
        let y = Int(Double(config.height) * max(0.0, min(1.0, normalizedY)))

        Task {
            _ = try? await ADBService.shared.executeCommand(
                adbPath: adb,
                serial: serial,
                arguments: ["shell", "input", "tap", "\(x)", "\(y)"]
            )
            try? await Task.sleep(nanoseconds: 200_000_000)
            self.captureScreen()
        }
    }

    public func handleScreenSwipe(startX: Double, startY: Double, endX: Double, endY: Double, durationMs: Int = 150) {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial, state.isRunning else { return }
        let x1 = Int(Double(config.width) * max(0.0, min(1.0, startX)))
        let y1 = Int(Double(config.height) * max(0.0, min(1.0, startY)))
        let x2 = Int(Double(config.width) * max(0.0, min(1.0, endX)))
        let y2 = Int(Double(config.height) * max(0.0, min(1.0, endY)))

        Task {
            _ = try? await ADBService.shared.executeCommand(
                adbPath: adb,
                serial: serial,
                arguments: ["shell", "input", "swipe", "\(x1)", "\(y1)", "\(x2)", "\(y2)", "\(durationMs)"]
            )
            try? await Task.sleep(nanoseconds: 250_000_000)
            self.captureScreen()
        }
    }

    // MARK: - 7. OTA / Update Checker

    public func checkForUpdates() {
        isCheckingForUpdates = true
        Task {
            let info = await UpdateCheckerService.shared.checkForUpdates()
            await MainActor.run {
                self.isCheckingForUpdates = false
                self.updateInfo = info
                if info.hasUpdate {
                    self.showAlertMessage("A new version of AndroMac is available: v\(info.latestVersion)!\n\n\(info.releaseNotes)")
                } else {
                    self.showAlertMessage("AndroMac is up to date (v\(info.currentVersion)).")
                }
            }
        }
    }

    // MARK: - App & APK Management

    public func installAPK(from url: URL) {
        guard let adb = report.adbPath else {
            showAlertMessage("ADB path not found.")
            return
        }
        guard let serial = EmulatorProcessManager.shared.activeSerial else {
            showAlertMessage("Android Tablet is not currently running.")
            return
        }

        isInstallingAPK = true
        apkInstallResult = nil

        Task {
            let res = await APKInstallerService.shared.installAPK(at: url, adbPath: adb, serial: serial)
            await MainActor.run {
                self.isInstallingAPK = false
                self.apkInstallResult = res
                self.refreshInstalledApps()
            }
        }
    }

    public func refreshInstalledApps() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            let apps = await ADBService.shared.listInstalledPackages(adbPath: adb, serial: serial)
            await MainActor.run {
                self.installedApps = apps
            }
        }
    }

    public func launchApp(packageName: String) {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            try? await ADBService.shared.launchApp(adbPath: adb, serial: serial, packageName: packageName)
            FullScreenCoordinator.shared.focusEmulatorWindow()
        }
    }

    public func uninstallApp(packageName: String) {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            try? await ADBService.shared.uninstallApp(adbPath: adb, serial: serial, packageName: packageName)
            self.refreshInstalledApps()
        }
    }

    // MARK: - Basic Navigation Shortcuts

    public func sendBack() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            try? await ADBService.shared.sendBack(adbPath: adb, serial: serial)
            if self.isLiveStreaming {
                try? await Task.sleep(nanoseconds: 150_000_000)
                self.captureScreen()
            }
        }
    }

    public func sendHome() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            try? await ADBService.shared.sendHome(adbPath: adb, serial: serial)
            if self.isLiveStreaming {
                try? await Task.sleep(nanoseconds: 150_000_000)
                self.captureScreen()
            }
        }
    }

    public func sendRecents() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            try? await ADBService.shared.sendRecents(adbPath: adb, serial: serial)
            if self.isLiveStreaming {
                try? await Task.sleep(nanoseconds: 150_000_000)
                self.captureScreen()
            }
        }
    }

    public func sendVolumeUp() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task { try? await ADBService.shared.sendVolumeUp(adbPath: adb, serial: serial) }
    }

    public func sendVolumeDown() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task { try? await ADBService.shared.sendVolumeDown(adbPath: adb, serial: serial) }
    }

    public func expandNotifications() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            try? await ADBService.shared.expandNotifications(adbPath: adb, serial: serial)
            if self.isLiveStreaming {
                try? await Task.sleep(nanoseconds: 200_000_000)
                self.captureScreen()
            }
        }
    }

    public func expandQuickSettings() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            try? await ADBService.shared.expandQuickSettings(adbPath: adb, serial: serial)
            if self.isLiveStreaming {
                try? await Task.sleep(nanoseconds: 200_000_000)
                self.captureScreen()
            }
        }
    }

    public func openPlayStore() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            try? await ADBService.shared.openPlayStore(adbPath: adb, serial: serial)
            FullScreenCoordinator.shared.focusEmulatorWindow()
        }
    }

    public func setOrientation(landscape: Bool) {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            try? await ADBService.shared.setOrientation(adbPath: adb, serial: serial, landscape: landscape)
            if self.isLiveStreaming {
                try? await Task.sleep(nanoseconds: 300_000_000)
                self.captureScreen()
            }
        }
    }

    public func sendClipboardText() {
        guard let clip = NSPasteboard.general.string(forType: .string), !clip.isEmpty else { return }
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            try? await ADBService.shared.sendTextInput(adbPath: adb, serial: serial, text: clip)
        }
    }

    public func captureScreen() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            let img = await ADBService.shared.captureScreenshot(adbPath: adb, serial: serial)
            await MainActor.run {
                self.screenPreview = img
            }
        }
    }

    public func applyConfigAndReconfigure() {
        config.save()
        do {
            try AVDManager.shared.configureAVD(config: config, report: report)
            showAlertMessage("Tablet configuration saved! Restart Android Tablet to apply changes.")
        } catch {
            showAlertMessage("Failed to update AVD: \(error.localizedDescription)")
        }
    }

    public func wipeData() {
        guard !state.isRunning else {
            showAlertMessage("Please stop the Android Tablet before wiping data.")
            return
        }
        do {
            try AVDManager.shared.wipeData(avdName: config.avdName)
            showAlertMessage("Android user data successfully wiped. Next boot will be a clean setup.")
        } catch {
            showAlertMessage("Failed to wipe data: \(error.localizedDescription)")
        }
    }

    public func refreshLogs() {
        logs = EmulatorProcessManager.shared.getRecentLogs()
    }

    private func startMetricsPolling() {
        metricsTimer?.invalidate()
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshMetrics()
                self?.refreshLogs()
            }
        }
    }

    private func stopMetricsPolling() {
        metricsTimer?.invalidate()
        metricsTimer = nil
    }

    private func refreshMetrics() {
        guard let adb = report.adbPath, let serial = EmulatorProcessManager.shared.activeSerial else { return }
        Task {
            var m = await ADBService.shared.getMetrics(adbPath: adb, serial: serial)
            let usage = EmulatorProcessManager.shared.getProcessResourceUsage()
            m.cpuUsagePercent = usage.cpu
            m.memoryUsageMB = usage.memMB
            await MainActor.run {
                self.metrics = m
            }
        }
    }

    public func showAlertMessage(_ msg: String) {
        alertMessage = msg
        showAlert = true
    }
}
