// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "doko-ui",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "DokoUI", targets: ["DokoUI"]),
    .library(name: "TripsUI", targets: ["TripsUI"]),
    .library(name: "ChargesUI", targets: ["ChargesUI"]),
    .library(name: "SettingsUI", targets: ["SettingsUI"]),
    .library(name: "VehiclesUI", targets: ["VehiclesUI"]),
    .library(name: "LocationsUI", targets: ["LocationsUI"]),
    .library(name: "CommonUI", targets: ["CommonUI"]),
  ],
  dependencies: [
    .package(path: "../doko-core"),
    .package(path: "../doko-sharing"),
    .package(path: "../doko-debug"),
    .package(path: "../doko-logging"),
    .package(path: "../doko-schema"),
    .package(path: "../doko-state-engine"),
    .package(path: "../doko-managers"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.4.3"),
    .package(url: "https://github.com/pointfreeco/swift-navigation", from: "2.6.0"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.7.2"),
  ],
  targets: [
    .target(
      name: "DokoUI",
      dependencies: ["TripsUI", "ChargesUI", "SettingsUI", "VehiclesUI", "LocationsUI"]
    ),
    .target(
      name: "TripsUI",
      dependencies: [
        "CommonUI",
        "VehiclesUI",
        "LocationsUI",
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoVehicleManager", package: "doko-managers"),
        .product(name: "DokoLocationManager", package: "doko-managers"),
        .product(name: "DokoSchema", package: "doko-schema"),
      ]
    ),
    .target(
      name: "ChargesUI",
      dependencies: [
        "CommonUI",
        "VehiclesUI",
        "LocationsUI",
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoVehicleManager", package: "doko-managers"),
        .product(name: "DokoLocationManager", package: "doko-managers"),
        .product(name: "DokoSchema", package: "doko-schema"),
      ]
    ),
    .target(
      name: "SettingsUI",
      dependencies: [
        "TripsUI",
        "ChargesUI",
        "VehiclesUI",
        "LocationsUI",
        "CommonUI",
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoDebug", package: "doko-debug"),
        .product(name: "DokoLogging", package: "doko-logging"),
        .product(name: "DokoVehicleManager", package: "doko-managers"),
        .product(name: "DokoStateEngine", package: "doko-state-engine"),
        .product(name: "DokoSchema", package: "doko-schema"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "SwiftUINavigation", package: "swift-navigation"),
        .product(name: "CasePaths", package: "swift-case-paths"),
      ]
    ),
    .target(
      name: "VehiclesUI",
      dependencies: [
        "CommonUI",
        .product(name: "DokoSchema", package: "doko-schema"),
      ]
    ),
    .target(
      name: "LocationsUI",
      dependencies: [
        "CommonUI",
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoSchema", package: "doko-schema"),
      ]
    ),
    .target(
      name: "CommonUI",
      dependencies: [
        .product(name: "DokoSharing", package: "doko-sharing"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
