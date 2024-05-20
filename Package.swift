// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-lox",
  platforms: [
    .macOS(.v12)
  ],
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
    ),
    .package(
      url: "https://github.com/apple/swift-tools-support-core",
      .upToNextMinor(from: "0.6.0")
    ),
  ],
  targets: [
    .target(
      name: "Lox",
      plugins: [
        .plugin(name: "LoxASTPlugin")
      ]
    ),
    .testTarget(
      name: "LoxTests",
      dependencies: ["Lox"]
    ),
    .executableTarget(
      name: "LoxCLI",
      dependencies: [
        .target(name: "Lox"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ]
    ),
    .executableTarget(
      name: "LoxAST",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "SwiftToolsSupport", package: "swift-tools-support-core")
      ]
    ),
    .plugin(
      name: "LoxASTPlugin",
      capability: .buildTool,
      dependencies: [
        .target(name: "LoxAST")
      ]
    )
  ]
)
