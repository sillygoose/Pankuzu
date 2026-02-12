// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "doko-core",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "DokoTypes", targets: ["DokoTypes"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", from: "1.3.0"),
  ],
  targets: [
    .target(
      name: "DokoTypes",
      dependencies: [
        .product(name: "OrderedCollections", package: "swift-collections"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
