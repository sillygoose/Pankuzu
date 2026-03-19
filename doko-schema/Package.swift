// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "doko-schema",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "DokoSchema", targets: ["DokoSchema"]),
    .library(name: "Vehicles", targets: ["Vehicles"]),
    .library(name: "Locations", targets: ["Locations"]),
    .library(name: "Trips", targets: ["Trips"]),
    .library(name: "Charges", targets: ["Charges"]),
    .library(name: "AppDatabase", targets: ["AppDatabase"]),
    .library(name: "DokoSchemaTypes", targets: ["DokoSchemaTypes"]),
  ],
  dependencies: [
    .package(path: "../doko-core"),
    .package(path: "../doko-managers"),
    .package(path: "../doko-sharing"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.6.0"),
  ],
  targets: [
    .target(
      name: "DokoSchema",
      dependencies: ["Vehicles", "Locations", "Trips", "Charges", "AppDatabase", "DokoSchemaTypes"]
    ),
    .target(
      name: "Vehicles",
      dependencies: [
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "Locations",
      dependencies: [
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "Trips",
      dependencies: [
        "Vehicles",
        "Locations",
        "DokoSchemaTypes",
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoLocationManager", package: "doko-managers"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "Charges",
      dependencies: [
        "Vehicles",
        "Locations",
        "DokoSchemaTypes",
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "DokoLocationManager", package: "doko-managers"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "AppDatabase",
      dependencies: [
        "Vehicles",
        "Locations",
        "Trips",
        "Charges",
        "DokoSchemaTypes",
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "SQLiteData", package: "sqlite-data"),
      ]
    ),
    .target(
      name: "DokoSchemaTypes",
      dependencies: [
        .product(name: "DokoTypes", package: "doko-core"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
