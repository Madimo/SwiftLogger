// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Logger",
    platforms: [.iOS(.v10), .macOS(.v10_12), .tvOS(.v9), .watchOS(.v2)],
    products: [
        .library(
            name: "Logger",
            targets: ["Logger"]
        )
    ],
    targets: [
        .target(
            name: "Logger"
        ),
        .target(
            name: "LoggerDemo",
            dependencies: ["Logger"]
        ),
        .testTarget(
            name: "LoggerTests",
            dependencies: ["Logger"]
        ),
    ]
)
