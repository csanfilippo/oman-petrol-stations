// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "oman-petrol-stations",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
        .package(url: "https://github.com/yaslab/CSV.swift", from: "2.5.2"),
        .package(url: "https://github.com/tid-kijyun/Kanna.git", from: "6.0.1"),
        .package(url: "https://github.com/csanfilippo/altai", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "oman-petrol-stations",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CSV", package: "CSV.swift"),
                .product(name: "Kanna", package: "Kanna"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "altai", package: "altai"),
                .product(name: "OrderedCollections", package: "swift-collections")
            ]
        ),
        .testTarget(
            name: "oman-petrol-stations-tests",
            dependencies: ["oman-petrol-stations"]
        )
    ],
    swiftLanguageModes: [.v6]
)
