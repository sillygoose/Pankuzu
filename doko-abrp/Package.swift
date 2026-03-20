// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "doko-abrp",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "DokoABRP", targets: ["DokoABRP"]),
  ],
  dependencies: [
    .package(path: "../doko-core"),
    .package(path: "../doko-sharing"),
    .package(path: "../doko-logging"),
  ],
  targets: [
    .target(
      name: "DokoABRP",
      dependencies: [
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoLogging", package: "doko-logging"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
