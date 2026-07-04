// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DicyaninGestureTipGhostHands",
    platforms: [
        .visionOS(.v2),
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "DicyaninGestureTipGhostHands",
            targets: ["DicyaninGestureTipGhostHands"]
        )
    ],
    targets: [
        .target(
            name: "DicyaninGestureTipGhostHands",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
