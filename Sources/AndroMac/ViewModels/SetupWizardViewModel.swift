import Foundation
import SwiftUI

@MainActor
public final class SetupWizardViewModel: ObservableObject {
    @Published public var steps: [SetupStep] = []
    @Published public var isRunningStep: Bool = false
    @Published public var isAllComplete: Bool = false
    @Published public var customSDKPath: String = ""

    public init() {
        initializeSteps()
        runAutomaticAudit()
    }

    private func initializeSteps() {
        steps = [
            SetupStep(
                id: "apple_silicon",
                title: "1. Apple Silicon Hardware Audit",
                description: "Verify that this Mac is running an Apple Silicon (M1/M2/M3/M4) ARM64 processor for hypervisor hardware virtualization."
            ),
            SetupStep(
                id: "sdk_tools",
                title: "2. Android SDK & Core Tools",
                description: "Detect official Android SDK installation, adb, and emulator binaries."
            ),
            SetupStep(
                id: "system_image",
                title: "3. ARM64 Google Play System Image",
                description: "Confirm presence of an official Google Play-enabled ARM64 system image (Android 34/35/36)."
            ),
            SetupStep(
                id: "avd_configuration",
                title: "4. AndroMac Tablet AVD Setup",
                description: "Configure a 16:10 Landscape Android Tablet Virtual Device (2560x1600 @ 280 DPI) with host GPU acceleration."
            ),
            SetupStep(
                id: "play_store_ready",
                title: "5. Google Play Store & Ready Check",
                description: "Ensure Google Play Store services are active and ready for account sign-in."
            )
        ]
    }

    public func runAutomaticAudit() {
        let rep = EnvironmentDetector.shared.detect()

        // Step 1: Apple Silicon
        if rep.isAppleSilicon {
            updateStep(id: "apple_silicon", status: .success, detail: "Mac Architecture: \(rep.macArchitecture) (Apple Silicon Native)")
        } else {
            updateStep(id: "apple_silicon", status: .failed("Architecture is \(rep.macArchitecture). Apple Silicon is required."), detail: nil)
        }

        // Step 2: Android SDK
        if let sdk = rep.sdkPath, rep.adbPath != nil, rep.emulatorPath != nil {
            updateStep(id: "sdk_tools", status: .success, detail: "SDK found at \(sdk). adb & emulator ready.")
        } else {
            updateStep(id: "sdk_tools", status: .failed("Missing SDK or binaries. Standard path is ~/Library/Android/sdk."), detail: nil)
        }

        // Step 3: ARM64 System Image
        if rep.hasGooglePlayArm64Image {
            let img = rep.availableSystemImages.first(where: { $0.contains("google_apis_playstore") && $0.contains("arm64") }) ?? "ARM64 Image"
            updateStep(id: "system_image", status: .success, detail: "Verified: \(img)")
        } else {
            updateStep(id: "system_image", status: .failed("No Google Play ARM64 image found in SDK/system-images."), detail: nil)
        }

        // Step 4: AVD
        let avdExists = AVDManager.shared.doesAVDExist(named: "AndroMac_Laptop") || AVDManager.shared.doesAVDExist(named: "AndroMac_Tablet")
        if avdExists {
            updateStep(id: "avd_configuration", status: .success, detail: "AndroMac AVD configured (16:10 Laptop & Tablet, Host GPU acceleration).")
        } else {
            updateStep(id: "avd_configuration", status: .pending, detail: "Ready to configure automatically.")
        }

        // Step 5: Play Store
        if rep.hasGooglePlayArm64Image && avdExists {
            updateStep(id: "play_store_ready", status: .success, detail: "Google Play Store enabled. Sign in with your Google Account inside Android.")
        } else {
            updateStep(id: "play_store_ready", status: .pending, detail: nil)
        }

        checkCompletion()
    }

    public func autoFixAll() async {
        isRunningStep = true
        let rep = EnvironmentDetector.shared.detect()

        if rep.hasGooglePlayArm64Image {
            let config = TabletConfig.load()
            do {
                try AVDManager.shared.configureAVD(config: config, report: rep)
                updateStep(id: "avd_configuration", status: .success, detail: "AndroMac_Tablet AVD successfully created & configured!")
                updateStep(id: "play_store_ready", status: .success, detail: "Ready to launch! You can sign into your Google Account inside Android.")
            } catch {
                updateStep(id: "avd_configuration", status: .failed(error.localizedDescription), detail: nil)
            }
        }

        runAutomaticAudit()
        isRunningStep = false
    }

    public func setCustomSDKPath(_ path: String) {
        UserDefaults.standard.set(path, forKey: "CustomAndroidSDKPath")
        runAutomaticAudit()
    }

    private func updateStep(id: String, status: SetupStep.StepStatus, detail: String?) {
        if let idx = steps.firstIndex(where: { $0.id == id }) {
            steps[idx].status = status
            steps[idx].detail = detail
        }
    }

    private func checkCompletion() {
        isAllComplete = steps.allSatisfy {
            if case .success = $0.status { return true }
            return false
        }
    }
}
