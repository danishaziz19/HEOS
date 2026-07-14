// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Core", targets: ["Core"])
    ],
    targets: [
        .target(
            name: "Core",
            resources: [
                // Bundled "Mock Data" resources for the Settings toggle —
                // same shape as the real devices.json / nowplaying.json
                // endpoints, deliberately using different sample content
                // so it's visually obvious in the app when the toggle is
                // switched, for easy verification during review.
                .copy("Data/Resources/devices_mock.json"),
                .copy("Data/Resources/nowplaying_mock.json")
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            resources: [
                .copy("Fixtures/devices.json"),
                .copy("Fixtures/nowplaying.json")
            ]
        )
    ]
)
