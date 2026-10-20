import Foundation

public struct AndroidFileItem: Identifiable, Hashable, Sendable {
    public var id: String { remotePath }
    public let name: String
    public let remotePath: String
    public let sizeBytes: Int64
    public let isDirectory: Bool
    public let modifiedDate: String

    public init(name: String, remotePath: String, sizeBytes: Int64, isDirectory: Bool, modifiedDate: String) {
        self.name = name
        self.remotePath = remotePath
        self.sizeBytes = sizeBytes
        self.isDirectory = isDirectory
        self.modifiedDate = modifiedDate
    }

    public var formattedSize: String {
        if isDirectory { return "--" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }

    public var systemIcon: String {
        if isDirectory { return "folder.fill" }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "webp", "gif", "heic":
            return "photo.fill"
        case "mp4", "mkv", "mov", "webm", "avi":
            return "film.fill"
        case "mp3", "m4a", "flac", "wav", "aac":
            return "music.note"
        case "pdf":
            return "doc.richtext.fill"
        case "txt", "md", "json", "xml", "csv":
            return "doc.text.fill"
        case "apk":
            return "arrow.down.doc.fill"
        case "zip", "tar", "gz", "7z", "rar":
            return "archivebox.fill"
        default:
            return "doc.fill"
        }
    }
}
