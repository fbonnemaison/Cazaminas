// swift-tools-version: 6.0
// Cazaminas — © 2026 App-Zilla. Licencia MIT.

import PackageDescription

let package = Package(
    name: "CazaminasCore",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(name: "CazaminasCore", targets: ["CazaminasCore"]),
    ],
    targets: [
        .target(name: "CazaminasCore"),
        .testTarget(name: "CazaminasCoreTests", dependencies: ["CazaminasCore"]),
    ]
)
