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
    .library(name: "FordMachE", targets: ["FordMachE"]),
    .library(name: "VwElectrics", targets: ["VwElectrics"]),
    .library(name: "VehicleCommon", targets: ["VehicleCommon"]),
    .library(name: "FordCommon", targets: ["FordCommon"]),
  ],
  dependencies: [
    .package(path: "../doko-core"),
    .package(path: "../doko-schema"),
    .package(path: "../doko-logging"),
    .package(path: "../doko-sharing"),
    .package(path: "../doko-managers"),
    .package(path: "../obdlink-core"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.6.0"),
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
        "VehicleCommon",
        .product(name: "ObdLinkCore", package: "obdlink-core"),
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "Vehicles", package: "doko-schema"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoLogging", package: "doko-logging"),
      ]
    ),
    .target(
      name: "FordElectrics",
      dependencies: [
        "VehicleInterface",
        "VehicleCommon",
        "FordCommon",
        .product(name: "ObdLinkCore", package: "obdlink-core"),
        .product(name: "Vehicles", package: "doko-schema"),
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "CoreLocationManager", package: "doko-managers"),
        .product(name: "DokoWeatherManager", package: "doko-managers"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoLogging", package: "doko-logging"),
      ]
    ),
    .target(
      name: "FordMachE",
      dependencies: [
        "VehicleInterface",
        "VehicleCommon",
        "FordCommon",
        .product(name: "ObdLinkCore", package: "obdlink-core"),
        .product(name: "Vehicles", package: "doko-schema"),
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "CoreLocationManager", package: "doko-managers"),
        .product(name: "DokoWeatherManager", package: "doko-managers"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoLogging", package: "doko-logging"),
      ]
    ),
    .target(
      name: "VwElectrics",
      dependencies: [
        "VehicleInterface",
        "VehicleCommon",
        .product(name: "ObdLinkCore", package: "obdlink-core"),
        .product(name: "Vehicles", package: "doko-schema"),
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "CoreLocationManager", package: "doko-managers"),
        .product(name: "DokoWeatherManager", package: "doko-managers"),
        .product(name: "DokoSharing", package: "doko-sharing"),
        .product(name: "DokoLogging", package: "doko-logging"),
      ]
    ),
    .target(
      name: "VehicleCommon",
      dependencies: [
        .product(name: "Parsing", package: "swift-parsing"),
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "ObdLinkCore", package: "obdlink-core"),
        .product(name: "DokoLogging", package: "doko-logging"),
      ]
    ),
    .target(
      name: "FordCommon",
      dependencies: [
        "VehicleCommon",
        .product(name: "DokoTypes", package: "doko-core"),
        .product(name: "ObdLinkCore", package: "obdlink-core"),
        .product(name: "CoreLocationManager", package: "doko-managers"),
        .product(name: "DokoWeatherManager", package: "doko-managers"),
        .product(name: "DokoLogging", package: "doko-logging"),
        .product(name: "DokoSharing", package: "doko-sharing"),
      ]
    ),
    .testTarget(
      name: "VehicleCommonTests",
      dependencies: [
        "VehicleCommon",
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
