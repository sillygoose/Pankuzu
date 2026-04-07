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

  public init() {}

  @Selection
  struct Stats {
    var count = 0
  }
}

public struct SettingsView: View {
  @Bindable var model: SettingsModel
  
  @State private var path = NavigationPath()
  @Shared(.appSettings) var appSettings

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
              color: .yellow,
              value: nil,
              units: nil,
              symbolName: "info.circle.fill",
              title: "About"
            ) {
              path.append(Destination.about)
            }

            DokoGridValueButton(
              color: appSettings.backgroundMode ? .blue : .red,
              value: nil,
              units: nil,
              symbolName: appSettings.backgroundMode ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash",
              title: "Bluetooth"
            ) {
              $appSettings.backgroundMode.withLock { $0.toggle() }
            }
          }

          GridRow {
            DokoGridValueButton(
              color: .cyan,
              value: "\(model.vehicleStats.count)",
              units: nil,
              symbolName: "car.2",
              title: "Vehicles"
            ) {
              path.append(Destination.vehicleSettings)
            }

            DokoGridValueButton(
              color: .blue,
              value: "\(model.locationStats.count)",
              units: nil,
              symbolName: "location",
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
              symbolName: "network",
              title: "Database"
            ) {
              path.append(Destination.databaseSettings)
            }

            DokoGridValueButton(
              color: .purple,
              value: nil,
              units: nil,
              symbolName: "leaf",
              title: "Add Trip/Charge"
            ) {
              path.append(Destination.databseSeeding)
            }
          }

          GridRow {
            DokoGridValueButton(
              color: .orange,
              value: nil,
              units: nil,
              symbolName: "ruler",
              title: "Units"
            ) {
              path.append(Destination.unitsSettings)
            }

            DokoGridValueButton(
              color: .teal,
              value: nil,
              units: nil,
              symbolName: "map.fill",
              title: "Maps"
            ) {
              path.append(Destination.mapsSettings)
            }
          }

          GridRow {
//            DokoGridValueButton(
//              color: .blue,
//              value: nil,
//              units: nil,
//              symbolName: "icloud",
//              title: "iCloud"
//            ) {
//              path.append(Destination.iCloudSettings)
//            }

            DokoGridValueButton(
              color: .indigo,
              value: nil,
              units: nil,
              symbolName: "arrow.trianglehead.2.clockwise",
              title: "Integrations"
            ) {
              path.append(Destination.integrations)
            }
            
            DokoGridValueButton(
              color: .gray,
              value: nil,
              units: nil,
              symbolName: "gearshape.2.fill",
              title: "Advanced"
            ) {
              path.append(Destination.advancedSettings)
            }

          }

          GridRow {
            DokoGridValueButton(
              color: .mint,
              value: nil,
              units: nil,
              symbolName: "wrench.and.screwdriver.fill",
              title: "Scan Tool"
            ) {
              path.append(Destination.scanTools)
            }

            DokoGridValueButton(
              color: .red,
              value: nil,
              units: nil,
              symbolName: "ladybug.circle.fill",
              title: "Debugging"
            ) {
              path.append(Destination.debugging)
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
        case .vehicleSettings:
          VehicleSettingsView(
            model: VehicleSettingsModel()
          )
        case .locationSettings:
          LocationSettingsView(
            model: LocationSettingsModel()
          )
        case .unitsSettings:
          UnitsSettingsView()
        case .mapsSettings:
          MapsSettingsView()
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
        case .integrations:
          IntegrationsView()
        case .scanTools:
          ScanToolsView(
            model: ScantoolSettingsModel()
          )
        }
      }
      .navigationTitle("")
    }
  }

  enum Destination: Hashable {
    case vehicleSettings
    case locationSettings
    case unitsSettings
    case mapsSettings
    case databaseSettings
    case about
    case debugging
    case databseSeeding
    case advancedSettings
    case iCloudSettings
    case integrations
    case scanTools
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
