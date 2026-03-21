// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "doko-managers",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "DokoPacketManager", targets: ["DokoPacketManager"]),
    .library(name: "CoreLocationManager", targets: ["CoreLocationManager"]),
    .library(name: "DokoLocationManager", targets: ["DokoLocationManager"]),
    .library(name: "DokoVehicleManager", targets: ["DokoVehicleManager"]),
    .library(name: "DokoWeatherManager", targets: ["DokoWeatherManager"]),
    .library(name: "DokoNotificationManager", targets: ["DokoNotificationManager"]),
    .library(name: "DokoLiveActivityManager", targets: ["DokoLiveActivityManager"]),
    .library(name: "DokoABRP", targets: ["DokoABRP"]),
  ],
  dependencies: [
    .package(path: "../doko-core"),
    .package(path: "../doko-schema"),
    .package(path: "../doko-logging"),
    .package(path: "../doko-sharing"),
    .package(path: "../doko-vehicle-interface"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.6.0"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.7.4"),
  ],
  targets: [
    .target(
      name: "DokoNotificationManager",
      dependencies: [
        .product(name: "DokoLogging", package: "doko-logging"),
      ]
    ),
    .target(
      name: "DokoWeatherManager",
      dependencies: [
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoLogging", package: "doko-logging"),
      ]
    ),
    .target(
      name: "DokoPacketManager",
      dependencies: [
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoLogging", package: "doko-logging"),
        .product(name: "DokoSharing", package: "doko-sharing"),
      ]
    ),
    .target(
      name: "CoreLocationManager",
      dependencies: [
        "DokoPacketManager",
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoLogging", package: "doko-logging"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "Sharing", package: "swift-sharing"),
      ]
    ),
    .target(
      name: "DokoLocationManager",
      dependencies: [
        .product(name: "DokoLogging", package: "doko-logging"),
        .product(name: "Locations", package: "doko-schema"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "SQLiteData", package: "sqlite-data"),
        .product(name: "Sharing", package: "swift-sharing"),
      ]
    ),
    .target(
      name: "DokoVehicleManager",
      dependencies: [
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoLogging", package: "doko-logging"),
        .product(name: "Vehicles", package: "doko-schema"),
        .product(name: "VehicleInterface", package: "doko-vehicle-interface"),
        .product(name: "UndeterminedVehicle", package: "doko-vehicle-interface"),
        .product(name: "FordElectrics", package: "doko-vehicle-interface"),
        .product(name: "FordMachE", package: "doko-vehicle-interface"),
        .product(name: "VwElectrics", package: "doko-vehicle-interface"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "DokoLiveActivityManager",
      dependencies: [
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoLogging", package: "doko-logging"),
      ]
    ),
    .target(
      name: "DokoABRP",
      dependencies: [
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoLogging", package: "doko-logging"),
        .product(name: "DokoSharing", package: "doko-sharing"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
