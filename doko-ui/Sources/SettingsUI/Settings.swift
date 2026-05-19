import Foundation
import SwiftUI
import TipKit

import CommonUI
import DokoSchema
import DokoSharing

@MainActor @Observable public final class SettingsModel {
  @ObservationIgnored @FetchOne(
    Trip
      .where { $0.isDeleted.eq(false) }
      .select { Stats.Columns(count: $0.count()) }
  ) var tripStats = Stats()

  @ObservationIgnored @FetchOne(
    Charge
      .where { $0.isDeleted.eq(false) }
      .select { Stats.Columns(count: $0.count()) }
  ) var chargeStats = Stats()

  @ObservationIgnored @FetchOne(
    Vehicle
      .select { Stats.Columns(count: $0.count()) }
  ) var vehicleStats = Stats()

  @ObservationIgnored @FetchOne(
    Location
      .where { $0.isDeleted.eq(false) }
      .select { Stats.Columns(count: $0.count()) }
  ) var locationStats = Stats()

  @ObservationIgnored @Shared(.connectedAccessoryName) var connectedAccessoryName
  @ObservationIgnored @Shared(.connectedVehicleModel) var connectedVehicleModel
  @ObservationIgnored @Shared(.activeSession) var activeSession
  @ObservationIgnored @Shared(.appSettings) var appSettings

  public var bluetoothEnableSymbol: String { return "power" }
  public var bluetoothEnableSymbolColor: Color { return  appSettings.backgroundMode ? .blue : .gray }
  
  public var bluetoothConnectedSymbol: String? {
    guard connectedAccessoryName != nil else { return "antenna.radiowaves.left.and.right.slash" }
    return "antenna.radiowaves.left.and.right"
  }
  public var bluetoothConnectedSymbolColor: Color? {
    guard connectedAccessoryName != nil else { return .gray }
    return .blue
  }

  public var activeSessionSymbol: String? { return activeSession?.symbol }
  public var activeSessionSymbolColor: Color? {
    guard activeSession != nil else { return nil }
    return .red
  }

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
  @State private var debuggingModel = DebuggingModel()
  @State private var showLogDialog = false
  @State private var debuggingLongPressed = false

  public init(model: SettingsModel) {
    self.model = model
  }

  public var body: some View {
    NavigationStack(path: $path) {
      TipView(ScanToolTip())
      List {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
          GridStatusButton(
            leftSymbol: model.bluetoothEnableSymbol,
            leftSymbolColor: model.bluetoothEnableSymbolColor,
            leftSymbolTitle: "Enable",
            centerSymbol: model.bluetoothConnectedSymbol,
            centerSymbolColor: model.bluetoothConnectedSymbolColor,
            centerSymbolTitle: "Bluetooth",
            rightSymbol: model.activeSessionSymbol,
            rightSymbolColor: model.activeSessionSymbolColor,
            rightSymbolTitle: "Activity"
          ) {
            $appSettings.backgroundMode.withLock { $0.toggle() }
          }

          Divider()
        }
        .listRowInsets(EdgeInsets())

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
          GridValue(
            color: .blue,
            value: "\(model.tripStats.count)",
            units: nil,
            symbolName: "point.bottomleft.forward.to.point.topright.scurvepath.fill",
            title: "Trips"
          )

          GridValue(
            color: .green,
            value: "\(model.chargeStats.count)",
            units: nil,
            symbolName: "bolt.car",
            title: "Charges"
          )

          GridValueButton(
            color: .cyan,
            value: "\(model.vehicleStats.count)",
            units: nil,
            symbolName: "car.2",
            title: "Vehicles"
          ) {
            path.append(Destination.vehicleSettings)
          }

          GridValueButton(
            color: .blue,
            value: "\(model.locationStats.count)",
            units: nil,
            symbolName: "location",
            title: "Locations"
          ) {
            path.append(Destination.locationSettings)
          }

          GridValueButton(
            color: .green,
            value: nil,
            units: nil,
            symbolName: "network",
            title: "Database"
          ) {
            path.append(Destination.databaseSettings)
          }

          GridValueButton(
            color: .purple,
            value: nil,
            units: nil,
            symbolName: "leaf",
            title: "Add Trip/Charge"
          ) {
            path.append(Destination.databseSeeding)
          }

          GridValueButton(
            color: .orange,
            value: nil,
            units: nil,
            symbolName: "ruler",
            title: "Units"
          ) {
            path.append(Destination.unitsSettings)
          }

//          GridValueButton(
//            color: .blue,
//            value: nil,
//            units: nil,
//            symbolName: "icloud",
//            title: "iCloud"
//          ) {
//            path.append(Destination.iCloudSettings)
//          }

          GridValueButton(
            color: .indigo,
            value: nil,
            units: nil,
            symbolName: "arrow.trianglehead.2.clockwise",
            title: "Integrations"
          ) {
            path.append(Destination.integrations)
          }

          GridValueButton(
            color: .mint,
            value: nil,
            units: nil,
            symbolName: "wrench.and.screwdriver.fill",
            title: "Scan Tool"
          ) {
            path.append(Destination.scanTools)
          }

          GridValueButton(
            color: .gray,
            value: nil,
            units: nil,
            symbolName: "gearshape.2.fill",
            title: "Advanced"
          ) {
            path.append(Destination.advancedSettings)
          }

          GridValueButton(
            color: .red,
            value: nil,
            units: nil,
            symbolName: "ladybug.circle.fill",
            title: "Debugging"
          ) {
            if debuggingLongPressed {
              debuggingLongPressed = false
            } else {
              path.append(Destination.debugging)
            }
          }
          .simultaneousGesture(LongPressGesture().onEnded { _ in
            debuggingLongPressed = true
            showLogDialog = true
          })

          GridValueButton(
            color: .yellow,
            value: nil,
            units: nil,
            symbolName: "info.circle.fill",
            title: "About"
          ) {
            path.append(Destination.about)
          }
        }
        .listRowInsets(EdgeInsets())
        TipView(DebuggingTip())
          .listRowInsets(EdgeInsets())
      }
      .listStyle(.plain)
      .confirmationDialog("Log", isPresented: $showLogDialog) {
        Button("Copy Log") {
          debuggingModel.saveHistoryToClipboard()
        }
        Button("Clear Log", role: .destructive) {
          debuggingModel.clearResponseHistory()
        }
      }
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
    }
  }

  enum Destination: Hashable {
    case vehicleSettings
    case locationSettings
    case unitsSettings
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
    let _ = try? Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.applicationDefault)])
    SettingsView(
      model: SettingsModel()
    )
    .preferredColorScheme(.dark)
  }
}
