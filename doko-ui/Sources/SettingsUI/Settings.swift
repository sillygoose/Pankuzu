import Foundation
import SwiftUI

import Sharing

import CommonUI
import DokoSchema
import DokoSharing

@MainActor
@Observable
public final class SettingsModel {
  @ObservationIgnored
  @FetchOne(Vehicle.select { Stats.Columns(count: $0.count()) })
  var vehicleStats = Stats()

  @ObservationIgnored
  @FetchOne(Location.where { !$0.isDeleted && !$0.isHidden }.select { Stats.Columns(count: $0.count()) })
  var locationStats = Stats()

  @ObservationIgnored
  @Shared(.connectedAccessory) var connectedAccessory
  @ObservationIgnored
  @Shared(.connectedVehicleModel) var connectedVehicleModel
  @ObservationIgnored
  @Shared(.activeSession) var activeSession

  public init() {}

  @Selection
  struct Stats {
    var count = 0
  }
}

//extension View {
//  func sessionToolbar(
//    connectedAccessory: String?,
//    connectedVehicleModel: String?,
//    activeSession: ActiveSession?
//  ) -> some View {
//    modifier(SessionToolbar(
//      connectedAccessory: connectedAccessory,
//      connectedVehicleModel: connectedVehicleModel,
//      activeSession: activeSession
//    ))
//  }
//}

public struct SettingsView: View {
  @Bindable var model: SettingsModel
  @State private var path = NavigationPath()
  
  public init(model: SettingsModel) {
    self.model = model
  }
  
  public var body: some View {
    NavigationStack(path: $path) {
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
              color: .cyan,
              value: "\(model.vehicleStats.count)",
              units: nil,
              iconName: "car.2",
              title: "Vehicles"
            ) {
              path.append(Destination.vehicleSettings)
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
              color: .blue,
              value:  "\(model.locationStats.count)",
              units: nil,
              iconName: "location",
              title: "Locations"
            ) {
              path.append(Destination.locationSettings)
            }
          }

          GridRow {
            DokoGridValueButton(
              color: .yellow,
              value: nil,
              units: nil,
              iconName: "info.circle.fill",
              title: "About"
            ) {
              path.append(Destination.about)
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
              color: .purple,
              value: nil,
              units: nil,
              iconName: "leaf",
              title: "Database Seeding"
            ) {
              path.append(Destination.databseSeeding)
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
        connectedAccessory: model.connectedAccessory,
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
        case .applicationSettings:
          ApplicationSettingsView(
            model: ApplicationSettingsModel()
          )
        case .databaseSettings:
          DatabaseSettingsView(
            model: DatabaseSettingsModel()
          )
        case .about:
          AboutView(
            model: AboutModel()
          )
        case .debugging:
          DebuggingView(
            model: DebuggingModel()
          )
        case .databseSeeding:
          DatabaseSeedingView(
            model: DatabaseSeedingModel()
          )
        }
      }
      .navigationTitle("Settings")
    }
  }
  
  enum Destination: Hashable {
    case vehicleSettings
    case locationSettings
    case applicationSettings
    case databaseSettings
    case about
    case debugging
    case databseSeeding
  }
}

#Preview {
  let _ = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    SettingsView(
      model: SettingsModel()
    )
    .preferredColorScheme(.dark)
  }
}
