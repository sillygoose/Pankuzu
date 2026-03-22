// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "obdlink-core",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "ObdLinkCore", targets: ["ObdLinkCore"]),
  ],
  dependencies: [
    .package(path: "../doko-core"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.11.0"),
  ],
  targets: [
    .target(
      name: "ObdLinkCore",
      dependencies: [
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "Dependencies", package: "swift-dependencies"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
