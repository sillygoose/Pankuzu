// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "doko-state-engine",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "DokoStateEngine", targets: ["DokoStateEngine"]),
  ],
  dependencies: [
    .package(path: "../doko-core"),
    .package(path: "../doko-sharing"),
    .package(path: "../doko-logging"),
    .package(path: "../doko-managers"),
    .package(path: "../doko-schema"),
  ],
  targets: [
    .target(
      name: "DokoStateEngine",
      dependencies: [
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoLogging", package: "doko-logging"),
        .product(name: "DokoPacketManager", package: "doko-managers"),
        .product(name: "DokoNotificationManager", package: "doko-managers"),
        .product(name: "DokoVehicleManager", package: "doko-managers"),
        .product(name: "CoreLocationManager", package: "doko-managers"),
        .product(name: "DokoLiveActivityManager", package: "doko-managers"),
        .product(name: "DokoABRP", package: "doko-managers"),
        .product(name: "DokoSchema", package: "doko-schema"),
      ]
    ),

  ],
  swiftLanguageModes: [.v6]
)
