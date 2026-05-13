// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ViaLinkCore",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ViaLinkCore", targets: ["ViaLinkCore"]),
    ],
    targets: [
        .binaryTarget(
            name: "ViaLinkCore",
            path: "ViaLinkCore.xcframework"
        ),
    ]
)
