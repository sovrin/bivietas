// swift-tools-version: 6.0
// Compiles the pure core of the app (bivietas/Core) so its unit tests run with `swift test`.
import PackageDescription

let package = Package(
    name: "bivietas",
    platforms: [.macOS(.v15)],
    targets: [
        .target(name: "BivietasCore", path: "bivietas/Core"),
        .testTarget(name: "BivietasCoreTests", dependencies: ["BivietasCore"], path: "Tests"),
    ],
    swiftLanguageModes: [.v5]
)
