import Foundation
import SwiftUI
import TipKit

import CommonUI
import DokoSchema
import DokoSharing


@MainActor @Observable public final class SettingsModel {
  @ObservationIgnored @FetchOne(Vehicle.select { Stats.Columns(count: $0.count()) })
  var vehicleStats = Stats()

  @ObservationIgnored @FetchOne(
    Location
      .where { $0.isDeleted.eq(false) }
      .select { Stats.Columns(count: $0.count()) }
  ) var locationStats = Stats()

  @ObservationIgnored @Shared(.connectedAccessoryName) var connectedAccessoryName
  @ObservationIgnored @Shared(.connectedVehicleModel) var connectedVehicleModel
  @ObservationIgnored @Shared(.activeSession) var activeSession
  @ObservationIgnored @Shared(.backgroundMode) var backgroundMode

  public init() {}

  @Selection
  struct Stats {
    var count = 0
  }
}

public struct SettingsView: View {
  @Bindable var model: SettingsModel
  @State private var path = NavigationPath()

  public init(model: SettingsModel) {
    self.model = model
  }

  public var body: some View {
    NavigationStack(path: $path) {
      TipView(SettingsTip())
      List {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
          GridRow {
            DokoGridValueButton(
              color: .gray,
              value: nil,
              units: nil,
              iconName: "gear",
              title: "Application"
            ) {
              path.append(Destination.applicationSettings)
            }

            DokoGridValueButton(
              color: model.backgroundMode ? .blue : .red,
              value: nil,
              units: nil,
              iconName: model.backgroundMode ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash",
              title: "Bluetooth"
            ) {
              path.append(Destination.bluetooth)
            }
          }

          GridRow {
            DokoGridValueButton(
              color: .cyan,
              value: "\(model.vehicleStats.count)",
              units: nil,
              iconName: "car.2",
              title: "Vehicles"
            ) {
              path.append(Destination.vehicleSettings)
            }

            DokoGridValueButton(
              color: .blue,
              value: "\(model.locationStats.count)",
              units: nil,
              iconName: "location",
              title: "Locations"
            ) {
              path.append(Destination.locationSettings)
            }
          }

          GridRow {
            DokoGridValueButton(
              color: .green,
              value: nil,
              units: nil,
              iconName: "network",
              title: "Database"
            ) {
              path.append(Destination.databaseSettings)
            }

            DokoGridValueButton(
              color: .yellow,
              value: nil,
              units: nil,
              iconName: "info.circle.fill",
              title: "About"
            ) {
              path.append(Destination.about)
            }
          }

          GridRow {
            DokoGridValueButton(
              color: .purple,
              value: nil,
              units: nil,
              iconName: "leaf",
              title: "Database Seeding"
            ) {
              path.append(Destination.databseSeeding)
            }

            DokoGridValueButton(
              color: .red,
              value: nil,
              units: nil,
              iconName: "ladybug.circle.fill",
              title: "Debugging"
            ) {
              path.append(Destination.debugging)
            }
          }

          GridRow {
            DokoGridValueButton(
              color: .gray,
              value: nil,
              units: nil,
              iconName: "gearshape.2.fill",
              title: "Advanced"
            ) {
              path.append(Destination.advancedSettings)
            }

            DokoGridValueButton(
              color: .blue,
              value: nil,
              units: nil,
              iconName: "icloud",
              title: "iCloud"
            ) {
              path.append(Destination.iCloudSettings)
            }
          }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .padding([.leading, .trailing], -20)
      }
      .listStyle(.plain)
      .padding(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
      .sessionToolbar(
        connectedAccessoryName: model.connectedAccessoryName,
        connectedVehicleModel: model.connectedVehicleModel,
        activeSession: model.activeSession
      )
      .navigationDestination(for: Destination.self) { destination in
        switch destination {
        case .bluetooth:
          BluetoothSettingsView(
            model: BluetoothSettingsModel()
          )
        case .vehicleSettings:
          VehicleSettingsView(
            model: VehicleSettingsModel()
          )
        case .locationSettings:
          LocationSettingsView(
            model: LocationSettingsModel()
          )
        case .applicationSettings:
          ApplicationSettingsView(
            model: ApplicationSettingsModel()
          )
        case .debugging:
          DebuggingView(
            model: DebuggingModel()
          )
        case .advancedSettings:
          AdvancedSettingsView()
        case .databaseSettings:
          DatabaseSettingsView(
            model: DatabaseSettingsModel()
          )
        case .about:
          AboutView(
            model: AboutModel()
          )
        case .databseSeeding:
          DatabaseSeedingView(
            model: DatabaseSeedingModel()
          )
        case .iCloudSettings:
          iCloudSettingsView(
            model: iCloudSettingsModel()
          )
        }
      }
      .navigationTitle("")
    }
  }

  enum Destination: Hashable {
    case bluetooth
    case vehicleSettings
    case locationSettings
    case applicationSettings
    case databaseSettings
    case about
    case debugging
    case databseSeeding
    case advancedSettings
    case iCloudSettings
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    SettingsView(
      model: SettingsModel()
    )
    .preferredColorScheme(.dark)
  }
}
