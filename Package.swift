// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ViaLinkSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)  // swift build (macOS) 호환용
    ],
    products: [
        .library(
            name: "ViaLinkSDK",
            type: .dynamic,
            targets: ["ViaLinkSDK"]
        ),
    ],
    targets: [
        .target(
            name: "ViaLinkSDK"
        ),
        .testTarget(
            name: "ViaLinkSDKTests",
            dependencies: ["ViaLinkSDK"]
        ),
    ]
)
