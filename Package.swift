// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "AndroMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "AndroMac",
            targets: ["AndroMac"]
        )
    ],
    targets: [
        .executableTarget(
            name: "AndroMac",
            path: "Sources/AndroMac",
            exclude: ["Resources/Info.plist", "Resources/AppIcon.icns"]
        )
    ]
)
