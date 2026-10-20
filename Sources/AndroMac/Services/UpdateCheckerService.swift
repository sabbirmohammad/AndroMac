import Foundation

public final class UpdateCheckerService: Sendable {
    public static let shared = UpdateCheckerService()

    public let currentVersion: String = "1.2.0"

    private init() {}

    public func checkForUpdates() async -> AppUpdateInfo {
        let repoURL = URL(string: "https://api.github.com/repos/sabbirmohammad/AndroMac/releases/latest")!
        var request = URLRequest(url: repoURL)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 5.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return AppUpdateInfo(
                    currentVersion: currentVersion,
                    latestVersion: currentVersion,
                    hasUpdate: false,
                    releaseNotes: "You are running the latest version of AndroMac (v\(currentVersion))."
                )
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tagName = json["tag_name"] as? String {
                let latestVer = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
                let body = json["body"] as? String ?? "New release available."
                let htmlURLStr = json["html_url"] as? String
                let releaseURL = htmlURLStr.flatMap { URL(string: $0) }
                let pubAt = json["published_at"] as? String ?? ""

                let isNewer = compareVersions(current: currentVersion, latest: latestVer) == .orderedAscending

                return AppUpdateInfo(
                    currentVersion: currentVersion,
                    latestVersion: latestVer,
                    hasUpdate: isNewer,
                    releaseNotes: body,
                    releaseURL: releaseURL,
                    publishedAt: pubAt
                )
            }
        } catch {
            // Offline or repository not public yet; fallback to up to date
        }

        return AppUpdateInfo(
            currentVersion: currentVersion,
            latestVersion: currentVersion,
            hasUpdate: false,
            releaseNotes: "AndroMac is up to date (v\(currentVersion))."
        )
    }

    private func compareVersions(current: String, latest: String) -> ComparisonResult {
        let cParts = current.split(separator: ".").compactMap { Int($0) }
        let lParts = latest.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(cParts.count, lParts.count) {
            let c = i < cParts.count ? cParts[i] : 0
            let l = i < lParts.count ? lParts[i] : 0
            if c < l { return .orderedAscending }
            if c > l { return .orderedDescending }
        }
        return .orderedSame
    }
}
