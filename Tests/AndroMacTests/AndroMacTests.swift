import XCTest
@testable import AndroMac

final class AndroMacTests: XCTestCase {
    func testEnvironmentDetection() {
        let report = EnvironmentDetector.shared.detect()
        XCTAssertTrue(report.isAppleSilicon, "Must detect Apple Silicon on this Mac")
        XCTAssertEqual(report.macArchitecture, "arm64", "Architecture must be arm64")
        XCTAssertNotNil(report.sdkPath, "Must locate Android SDK")
        XCTAssertNotNil(report.adbPath, "Must locate adb executable")
        XCTAssertNotNil(report.emulatorPath, "Must locate emulator executable")
        XCTAssertTrue(report.hasGooglePlayArm64Image, "Must find installed ARM64 Google Play system image")
        XCTAssertTrue(report.isReadyToRun, "Environment must be marked ready to run")
    }

    func testTabletConfigDefaults() {
        let config = TabletConfig.default
        XCTAssertEqual(config.width, 2560)
        XCTAssertEqual(config.height, 1600)
        XCTAssertEqual(config.density, 280)
        XCTAssertEqual(config.orientation, "landscape")
        XCTAssertTrue(config.playStoreEnabled)
        XCTAssertFalse(config.showDeviceFrame)
        XCTAssertEqual(config.ramMB, 3072)
        XCTAssertEqual(config.cpuCores, 4)
    }

    func testResolutionPresetsAspectRatio() {
        for preset in ResolutionPreset.presets {
            let ratio = Double(preset.width) / Double(preset.height)
            // 16:10 is 1.6
            XCTAssertEqual(ratio, 1.6, accuracy: 0.05, "Preset \(preset.name) must be approximately 16:10")
        }
    }

    func testDensityPresets() {
        let dpis = DensityPreset.presets.map { $0.dpi }
        XCTAssertTrue(dpis.contains(240))
        XCTAssertTrue(dpis.contains(280))
        XCTAssertTrue(dpis.contains(320))
    }

    func testEmulatorStateTransitions() {
        var state = EmulatorState.stopped
        XCTAssertFalse(state.isRunning)
        XCTAssertFalse(state.isTransitioning)

        state = .starting("QEMU Hypervisor")
        XCTAssertFalse(state.isRunning)
        XCTAssertTrue(state.isTransitioning)

        state = .booting("Loading system services")
        XCTAssertFalse(state.isRunning)
        XCTAssertTrue(state.isTransitioning)

        state = .running
        XCTAssertTrue(state.isRunning)
        XCTAssertFalse(state.isTransitioning)

        state = .shuttingDown("Saving state")
        XCTAssertFalse(state.isRunning)
        XCTAssertTrue(state.isTransitioning)
    }

    func testAVDConfigurationIntegrity() throws {
        let report = EnvironmentDetector.shared.detect()
        let config = TabletConfig.default
        try AVDManager.shared.configureAVD(config: config, report: report)

        let avdDir = "\(AVDManager.shared.avdHomeDirectory)/\(config.avdName).avd"
        let configIniPath = "\(avdDir)/config.ini"

        let content = try String(contentsOfFile: configIniPath, encoding: .utf8)
        XCTAssertTrue(content.contains("PlayStore.enabled=true"), "Play Store must be enabled")
        XCTAssertTrue(content.contains("hw.lcd.width=2560"), "Width must be 2560")
        XCTAssertTrue(content.contains("hw.lcd.height=1600"), "Height must be 1600")
        XCTAssertTrue(content.contains("hw.initialOrientation=landscape"), "Orientation must be landscape")
        XCTAssertTrue(content.contains("showDeviceFrame=no"), "Device frame must be disabled")
        XCTAssertTrue(content.contains("hw.keyboard=yes"), "Keyboard must be enabled")
        XCTAssertTrue(content.contains("hw.gpu.enabled=yes"), "GPU must be enabled")
    }

    func testAPKInstallErrorParsing() {
        let service = APKInstallerService.shared
        let url = URL(fileURLWithPath: "/nonexistent/test.apk")
        let expectation = expectation(description: "Install non-existent APK")

        Task {
            let res = await service.installAPK(at: url, adbPath: "/bin/echo", serial: "emulator-5554")
            XCTAssertFalse(res.isSuccess)
            XCTAssertTrue(res.message.contains("not found"))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFileItemFormatting() {
        let docItem = AndroidFileItem(
            name: "report.pdf",
            remotePath: "/sdcard/Download/report.pdf",
            sizeBytes: 1048576,
            isDirectory: false,
            modifiedDate: "2026-10-21 00:00"
        )
        XCTAssertEqual(docItem.systemIcon, "doc.richtext.fill")
        XCTAssertFalse(docItem.formattedSize.isEmpty)

        let photoItem = AndroidFileItem(
            name: "screenshot.png",
            remotePath: "/sdcard/Download/screenshot.png",
            sizeBytes: 2048,
            isDirectory: false,
            modifiedDate: "2026-10-21 00:00"
        )
        XCTAssertEqual(photoItem.systemIcon, "photo.fill")

        let dirItem = AndroidFileItem(
            name: "Folder",
            remotePath: "/sdcard/Download/Folder",
            sizeBytes: 0,
            isDirectory: true,
            modifiedDate: "2026-10-21 00:00"
        )
        XCTAssertEqual(dirItem.systemIcon, "folder.fill")
        XCTAssertEqual(dirItem.formattedSize, "--")
    }

    func testGameKeymapperPresets() {
        let presets = KeymapProfile.presets
        XCTAssertGreaterThanOrEqual(presets.count, 2)

        let actionFps = presets.first { $0.name.contains("Action") }
        XCTAssertNotNil(actionFps)
        let keys = actionFps?.mappings.map { $0.key } ?? []
        XCTAssertTrue(keys.contains("W"))
        XCTAssertTrue(keys.contains("A"))
        XCTAssertTrue(keys.contains("S"))
        XCTAssertTrue(keys.contains("D"))
        XCTAssertTrue(keys.contains("Space"))

        let dpad = presets.first { $0.name.contains("D-Pad") }
        XCTAssertNotNil(dpad)
        let dpadCodes = dpad?.mappings.map { $0.androidKeycode } ?? []
        XCTAssertTrue(dpadCodes.contains(19)) // DPAD_UP
        XCTAssertTrue(dpadCodes.contains(20)) // DPAD_DOWN
    }

    func testInstanceManagerDiscovery() {
        let instances = InstanceManager.shared.listInstances(
            currentAVDName: "AndroMac_Tablet",
            isEmulatorRunning: false
        )
        XCTAssertFalse(instances.isEmpty, "Should discover at least one AVD")
        let andromac = instances.first { $0.name == "AndroMac_Tablet" }
        XCTAssertNotNil(andromac)
        XCTAssertTrue(andromac?.isCurrent == true)
        XCTAssertEqual(andromac?.resolution, "2560x1600")
        XCTAssertEqual(andromac?.density, 280)
    }

    func testSnapshotServiceListing() {
        let snapshots = SnapshotService.shared.listSnapshots(avdName: "AndroMac_Tablet")
        // Just verify it queries safely without crashing
        XCTAssertNotNil(snapshots)
    }

    func testUpdateCheckerVersionComparison() {
        let service = UpdateCheckerService.shared
        XCTAssertEqual(service.currentVersion, "1.1.0")
        let expectation = expectation(description: "Check for updates")

        Task {
            let info = await service.checkForUpdates()
            XCTAssertNotNil(info.latestVersion)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}
