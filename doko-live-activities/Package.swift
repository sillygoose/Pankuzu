// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "doko-live-activities",
  platforms: [
    .iOS(.v26)
  ],
  products: [
    .library(name: "DokoLiveActivityManager", targets: ["DokoLiveActivityManager"])
  ],
  dependencies: [
    .package(path: "../doko-logging"),
    .package(path: "../doko-managers"),
  ],
  targets: [
    .target(
      name: "DokoLiveActivityManager",
      dependencies: [
        .product(name: "DokoLogging", package: "doko-logging"),
        .product(name: "DokoWeatherManager", package: "doko-managers"),
      ],
    )
  ],
  swiftLanguageModes: [.v6]
)
