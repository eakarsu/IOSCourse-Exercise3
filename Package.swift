// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MultiplesCore",
    platforms: [.macOS(.v13), .iOS(.v15)],
    products: [.library(name: "MultiplesCore", targets: ["MultiplesCore"])],
    targets: [
        .target(name: "MultiplesCore"),
        .testTarget(name: "MultiplesCoreTests", dependencies: ["MultiplesCore"])
    ]
)
