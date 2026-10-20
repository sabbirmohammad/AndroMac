import Foundation

public struct APKInstallResult: Sendable {
    public let isSuccess: Bool
    public let message: String
    public let rawOutput: String
    public let errorCode: String?

    public init(isSuccess: Bool, message: String, rawOutput: String, errorCode: String? = nil) {
        self.isSuccess = isSuccess
        self.message = message
        self.rawOutput = rawOutput
        self.errorCode = errorCode
    }
}

public final class APKInstallerService: Sendable {
    public static let shared = APKInstallerService()

    private init() {}

    public func installAPK(at fileURL: URL, adbPath: String, serial: String) async -> APKInstallResult {
        let path = fileURL.path

        guard FileManager.default.fileExists(atPath: path) else {
            return APKInstallResult(
                isSuccess: false,
                message: "APK file not found at path: \(path)",
                rawOutput: "File does not exist."
            )
        }

        guard fileURL.pathExtension.lowercased() == "apk" else {
            return APKInstallResult(
                isSuccess: false,
                message: "Selected file is not an Android Package (.apk).",
                rawOutput: "Invalid file extension."
            )
        }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64, size > 0 else {
            return APKInstallResult(
                isSuccess: false,
                message: "APK file is empty (0 bytes).",
                rawOutput: "File size is zero."
            )
        }

        do {
            let output = try await ADBService.shared.executeCommand(
                adbPath: adbPath,
                serial: serial,
                arguments: ["install", "-r", path]
            )

            if output.contains("Success") {
                return APKInstallResult(
                    isSuccess: true,
                    message: "APK installed successfully! The app is now ready on your Android Tablet.",
                    rawOutput: output
                )
            } else {
                return parseInstallFailure(output: output)
            }
        } catch {
            return parseInstallFailure(output: error.localizedDescription)
        }
    }

    private func parseInstallFailure(output: String) -> APKInstallResult {
        let code = extractErrorCode(from: output)
        let friendlyMessage: String

        switch code {
        case "INSTALL_FAILED_NO_MATCHING_ABIS":
            friendlyMessage = "Architecture Mismatch: This APK only contains x86 or 32-bit native libraries and cannot run on Apple Silicon ARM64 Android. Please use an arm64-v8a compatible APK."
        case "INSTALL_FAILED_INSUFFICIENT_STORAGE":
            friendlyMessage = "Storage Full: The Android Tablet does not have enough disk space. Increase storage in Settings or clean up existing apps."
        case "INSTALL_FAILED_ALREADY_EXISTS":
            friendlyMessage = "Conflict: An application with this package name already exists with a conflicting certificate signature."
        case "INSTALL_FAILED_VERSION_DOWNGRADE":
            friendlyMessage = "Downgrade Error: A newer version of this app is already installed on the tablet."
        case "INSTALL_FAILED_OLDER_SDK":
            friendlyMessage = "SDK Incompatible: This APK requires a newer Android version than currently running on the tablet."
        case "INSTALL_PARSE_FAILED_NOT_APK":
            friendlyMessage = "Corrupt File: The file is corrupted or not a valid Android APK archive."
        case "INSTALL_PARSE_FAILED_BAD_MANIFEST":
            friendlyMessage = "Manifest Error: AndroidManifest.xml in the APK is malformed or invalid."
        case "INSTALL_FAILED_USER_RESTRICTED":
            friendlyMessage = "Security Restriction: Installation is blocked by current device security profile."
        default:
            friendlyMessage = "Installation failed: \(output)"
        }

        return APKInstallResult(
            isSuccess: false,
            message: friendlyMessage,
            rawOutput: output,
            errorCode: code
        )
    }

    private func extractErrorCode(from output: String) -> String? {
        let pattern = "\\[(INSTALL_[A-Z_]+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let range = Range(match.range(at: 1), in: output) else {
            return nil
        }
        return String(output[range])
    }
}
