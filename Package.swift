// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SwiftLogger",
    platforms: [.iOS(.v10), .macOS(.v10_12), .tvOS(.v9), .watchOS(.v2)],
    products: [
        .library(
            name: "Logging",
            targets: ["Logging"]
        )
    ],
    targets: [
        .target(
            name: "Logging"
        ),
        .target(
            name: "LoggingDemo",
            dependencies: ["Logging"]
        ),
        .testTarget(
            name: "LoggingTests",
            dependencies: ["Logging"]
        ),
    ]
)
