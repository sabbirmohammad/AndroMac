import Foundation

public struct AppUpdateInfo: Equatable, Sendable {
    public let currentVersion: String
    public let latestVersion: String
    public let hasUpdate: Bool
    public let releaseNotes: String
    public let releaseURL: URL?
    public let publishedAt: String

    public init(
        currentVersion: String = "1.2.0",
        latestVersion: String = "1.2.0",
        hasUpdate: Bool = false,
        releaseNotes: String = "Up to date",
        releaseURL: URL? = nil,
        publishedAt: String = ""
    ) {
        self.currentVersion = currentVersion
        self.latestVersion = latestVersion
        self.hasUpdate = hasUpdate
        self.releaseNotes = releaseNotes
        self.releaseURL = releaseURL
        self.publishedAt = publishedAt
    }
}
