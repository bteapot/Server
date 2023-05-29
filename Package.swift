// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Server",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "Server",
            targets: ["Server"]
        ),
    ],
    targets: [
        .target(
            name: "Server"
        ),
    ]
)
