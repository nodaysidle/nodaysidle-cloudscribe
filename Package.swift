// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CloudScribe",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CloudScribe", targets: ["CloudScribe"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "CloudScribe",
            dependencies: [],
            path: "Sources/CloudScribe",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CloudScribeTests",
            dependencies: ["CloudScribe"],
            path: "Tests/CloudScribeTests",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
