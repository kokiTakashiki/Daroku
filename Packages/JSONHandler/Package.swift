// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSONHandler",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "JSONHandler",
            targets: ["JSONHandler"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "JSONHandler",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "JSONHandlerTests",
            dependencies: ["JSONHandler"]
        ),
    ]
)


