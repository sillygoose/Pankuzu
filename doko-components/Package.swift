// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "doko-components",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "ObdLinkManager", targets: ["ObdLinkManager"]),
  ],
  dependencies: [
    .package(path: "../doko-core"),
    .package(path: "../doko-logging"),
    .package(path: "../doko-sharing"),
    .package(path: "../doko-managers"),
    .package(path: "../obdlink-core"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.6.0"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.7.4"),
  ],
  targets: [
    .target(
      name: "ObdLinkManager",
      dependencies: [
        .product(name: "CoreLocationManager", package: "doko-managers"),
        .product(name: "DokoNotificationManager", package: "doko-managers"),
        .product(name: "DokoPacketManager", package: "doko-managers"),
        .product(name: "DokoVehicleManager", package: "doko-managers"),
        .product(name: "ObdLinkCore", package: "obdlink-core"),
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoLogging", package: "doko-logging"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "Sharing", package: "swift-sharing"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
