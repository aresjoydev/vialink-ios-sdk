// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ViaLinkCore",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)  // swift build (macOS) 호환용
    ],
    products: [
        .library(
            name: "ViaLinkCore",
            type: .dynamic,
            targets: ["ViaLinkCore"]
        ),
    ],
    targets: [
        .target(
            name: "ViaLinkCore"
        ),
        .testTarget(
            name: "ViaLinkCoreTests",
            dependencies: ["ViaLinkCore"]
        ),
    ]
)
