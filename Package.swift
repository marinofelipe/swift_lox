// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Lox",
    products: [
        .library(
            name: "Lox",
            targets: ["Lox"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Lox",
            dependencies: []
        ),
        .testTarget(
            name: "LoxTests",
            dependencies: ["Lox"]
        ),
    ]
)
