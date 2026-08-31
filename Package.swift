// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LiveEnglish",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "LiveEnglish", targets: ["LiveEnglish"])],
    targets: [
        .executableTarget(
            name: "LiveEnglish", path: "Sources/LiveEnglish",
            swiftSettings: [.unsafeFlags(["-Xfrontend", "-strict-concurrency=minimal"])]),
        .testTarget(name: "LiveEnglishTests", dependencies: ["LiveEnglish"], path: "Tests/LiveEnglishTests"),
    ]
)
