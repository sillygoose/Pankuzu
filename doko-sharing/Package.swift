// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "doko-sharing",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "DokoSharing", targets: ["DokoSharing"]),
  ],
  dependencies: [
    .package(path: "../doko-schema"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.7.4"),
  ],
  targets: [
    .target(
      name: "DokoSharing",
      dependencies: [
        .product(name: "Vehicles", package: "doko-schema"),
        .product(name: "Sharing", package: "swift-sharing"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
