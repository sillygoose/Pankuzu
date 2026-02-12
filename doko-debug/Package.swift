// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "doko-debug",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "DokoDebug", targets: ["DokoDebug"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.7.4"),
  ],
  targets: [
    .target(
      name: "DokoDebug",
      dependencies: [
        .product(name: "Sharing", package: "swift-sharing"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
