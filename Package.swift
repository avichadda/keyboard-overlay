// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Keyviz",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Keyviz", targets: ["Keyviz"])
    ],
    targets: [
        .executableTarget(
            name: "Keyviz",
            path: "Sources/Keyviz",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
