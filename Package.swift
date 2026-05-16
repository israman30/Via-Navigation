// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ViaNavigation",
    platforms: [
        .iOS(.v13),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "Via",
            targets: ["Via"]
        ),
        .library(
            name: "ViaDemoUI",
            targets: ["ViaDemoUI"]
        ),
    ],
    targets: [
        .target(
            name: "Via",
            path: "Via/Sources/Via"
        ),
        .target(
            name: "ViaDemoUI",
            dependencies: ["Via"],
            path: "Via/Examples"
        ),
    ],
    swiftLanguageModes: [.v6]
)

