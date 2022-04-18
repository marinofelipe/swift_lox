// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-lox",
    products: [
        .library(
            name: "Lox",
            targets: ["Lox"]
        ),
        .executable(
            name: "lox-cli",
            targets: ["LoxCLI"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            .upToNextMinor(from: "1.1.2")
        )
    ],
    targets: [
        .target(
            name: "Lox",
            dependencies: []
        ),
        .testTarget(
            name: "LoxTests",
            dependencies: ["Lox"]
        ),
        .target(
            name: "LoxCLI",
            dependencies: [
                .target(name: "Lox"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
