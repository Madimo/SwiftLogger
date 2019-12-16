// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Logger",
    platforms: [.iOS(.v9), .macOS(.v10_12), .tvOS(.v9), .watchOS(.v2)],
    products: [
        .library(
            name: "Logger",
            targets: ["Logger"]
        ),
    ],
    targets: [
        .target(
            name: "Logger"
        ),
        .testTarget(
            name: "LoggerTests",
            dependencies: ["Logger"]
        ),
    ]
)
