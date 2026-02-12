// swift-tools-version:6.2

import PackageDescription

let package = Package(
  name: "doko-vehicle-interface",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "VehicleInterface", targets: ["VehicleInterface"]),
    .library(name: "UndeterminedVehicle", targets: ["UndeterminedVehicle"]),
    .library(name: "FordElectrics", targets: ["FordElectrics"]),
    .library(name: "ParsingHelpers", targets: ["ParsingHelpers"]),
  ],
  dependencies: [
    .package(path: "../doko-core"),
    .package(path: "../doko-debug"),
    .package(path: "../doko-schema"),
    .package(path: "../doko-logging"),
    .package(path: "../doko-sharing"),
    .package(path: "../doko-managers"),
    .package(path: "../obdlink-core"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.4.3"),
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.14.1"),
  ],
  targets: [
    .target(
      name: "VehicleInterface",
      dependencies: [
        .product(name: "ObdLinkCore", package: "obdlink-core"),
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "Vehicles", package: "doko-schema"),
      ]
    ),
    .target(
      name: "UndeterminedVehicle",
      dependencies: [
        "VehicleInterface",
        "ParsingHelpers",
        .product(name: "ObdLinkCore", package: "obdlink-core"),
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "Vehicles", package: "doko-schema"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoDebug", package: "doko-debug"),
        .product(name: "DokoLogging", package: "doko-logging"),
      ]
    ),
    .target(
      name: "FordElectrics",
      dependencies: [
        "VehicleInterface",
        "ParsingHelpers",
        .product(name: "ObdLinkCore", package: "obdlink-core"),
        .product(name: "Vehicles", package: "doko-schema"),
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "CoreLocationManager", package: "doko-managers"),
        .product(name: "DokoWeatherManager", package: "doko-managers"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoDebug", package: "doko-debug"),
        .product(name: "DokoLogging", package: "doko-logging"),
      ]
    ),
    .target(
      name: "ParsingHelpers",
      dependencies: [
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
