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
  ],
  targets: [
    .target(
      name: "ObdLinkCore",
      dependencies: [
        .product(name: "DokoTypes", package: "doko-core"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
