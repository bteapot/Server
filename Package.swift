// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Server",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_14),
    ],
    products: [
        .library(
            name: "Server",
            targets: ["Server"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/ReactiveCocoa/ReactiveSwift.git",
            .init(6, 0, 0) ... .init(99, 0, 0)
        ),
    ],
    targets: [
        .target(
            name: "Server",
            dependencies: [
                "ReactiveSwift",
            ]
        ),
    ]
)

#if swift(>=5.6)
    package.dependencies.append(
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    )
#endif
