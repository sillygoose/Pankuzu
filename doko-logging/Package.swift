// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "doko-logging",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "DokoLogging", targets: ["DokoLogging"]),
  ],
  dependencies: [
    .package(path: "../doko-core"),
    .package(path: "../obdlink-core"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.7.4"),
    .package(url: "https://github.com/apple/swift-collections", from: "1.3.0"),
  ],
  targets: [
    .target(
      name: "DokoLogging",
      dependencies: [
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "ObdLinkCore", package: "obdlink-core"),
        .product(name: "Sharing", package: "swift-sharing"),
        .product(name: "DequeModule", package: "swift-collections"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
