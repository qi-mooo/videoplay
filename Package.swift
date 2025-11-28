// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Videoplay",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Videoplay",
            targets: ["Videoplay"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Videoplay",
            dependencies: [
            ])
    ]
)
