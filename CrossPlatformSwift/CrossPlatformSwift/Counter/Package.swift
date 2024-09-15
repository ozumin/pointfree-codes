// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Counter",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(
            name: "Counter",
            targets: ["Counter"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-navigation", from: "2.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-perception", from: "1.0.0"),
        .package(url: "https://github.com/swiftwasm/carton", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "WasmApp"
        ),
        .target(
            name: "Counter",
            dependencies: [
                .product(name: "SwiftNavigation", package: "swift-navigation"),
                .product(name: "Perception", package: "swift-perception")
            ]
        ),
    ],
    swiftLanguageVersions: [.v6]
)
