// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EmberCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "EmberCore", targets: ["EmberCore"])],
    targets: [
        .target(name: "EmberCore", path: "Engine"),
        .testTarget(name: "EmberCoreTests", dependencies: ["EmberCore"])
    ]
)
