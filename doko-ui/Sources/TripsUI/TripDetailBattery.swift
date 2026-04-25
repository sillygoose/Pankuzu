import SwiftUI
import Charts

import DokoTypes
import DokoSharing
import DokoSchema
import CommonUI

@MainActor
@Observable
public final class TripDetailBatteryModel {
  var trip: Trip
  
  @ObservationIgnored
  @Shared(.appSettings) var appSettings
  
  public init(
    trip: Trip
  ) {
    self.trip = trip
  }
}

public struct TripDetailBatteryView: View {
  @Bindable var model: TripDetailBatteryModel
  
  @Environment(\.dismiss) var dismiss
  
  public init(model: TripDetailBatteryModel) {
    self.model = model
  }
  
  public var body: some View {
    VStack {
      if let stateOfChargeStart = model.trip.stateOfChargeStart, let stateOfChargeEnd = model.trip.stateOfChargeEnd {
        let stateOfChargeStart = Measurement(value: stateOfChargeStart, unit: UnitPercent.percent)
        let stateOfChargeEnd = Measurement(value: stateOfChargeEnd, unit: UnitPercent.percent)
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
          GridRow {
            let (stateOfChargeStartColor, stateOfChargeStartIcon) = {
              if stateOfChargeStart.value < 25 { return (Color.red, "battery.25percent") }
              if stateOfChargeStart.value < 50 { return (Color.yellow,"battery.50percent") }
              return (Color.green, "battery.75percent")
            }()
            GridValue(
              color: stateOfChargeStartColor,
              value: String(format: "%.0f", stateOfChargeStart.value),
              units: stateOfChargeStart.unit.symbol,
              symbolName: stateOfChargeStartIcon,
              title: "Start SoC"
            )
            let (stateOfChargeEndColor, stateOfChargeEndIcon) = {
              if stateOfChargeEnd.value < 25 { return (Color.red, "battery.25percent") }
              if stateOfChargeEnd.value < 50 { return (Color.yellow,"battery.50percent") }
              return (Color.green, "battery.75percent")
            }()
            GridValue(
              color: stateOfChargeEndColor,
              value: String(format: "%.0f", stateOfChargeEnd.value),
              units: stateOfChargeEnd.unit.symbol,
              symbolName: stateOfChargeEndIcon,
              title: "End SoC"
            )
          }
        }
      }
 
      if let energyToEmptyStart = model.trip.energyToEmptyStart, let energyToEmptyEnd = model.trip.energy {
        let energyToEmptyStart = Measurement(value: energyToEmptyStart, unit: UnitEnergy.kilowattHours)
        let energyToEmptyEnd = Measurement(value: energyToEmptyEnd, unit: UnitEnergy.kilowattHours)
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
          GridRow {
            let (energyToEmptyStartColor, energyToEmptyStartIcon) = {
              if energyToEmptyStart.value < 25 { return (Color.red, "bolt") }
              if energyToEmptyStart.value < 50 { return (Color.yellow,"bolt") }
              return (Color.green, "bolt")
            }()
            GridValue(
              color: energyToEmptyStartColor,
              value: String(format: "%.1f", energyToEmptyStart.value),
              units: energyToEmptyStart.unit.symbol,
              symbolName: energyToEmptyStartIcon,
              title: "Start Energy"
            )

            let (energyToEmptyEndColor, energyToEmptyEndIcon) = {
              if energyToEmptyEnd.value < 25 { return (Color.red, "bolt") }
              if energyToEmptyEnd.value < 50 { return (Color.yellow,"bolt") }
              return (Color.green, "bolt")
            }()
            GridValue(
              color: energyToEmptyEndColor,
              value: String(format: "%.1f", energyToEmptyStart.value - energyToEmptyEnd.value),
              units: energyToEmptyEnd.unit.symbol,
              symbolName: energyToEmptyEndIcon,
              title: "End Energy"
            )
          }
        }
      }
      
      if let batteryTempStartMetric = model.trip.batteryTempStart, let batteryTempEndMetric = model.trip.batteryTempEnd {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
          GridRow {
            let (batteryTempStartColor, batteryTempStartIcon) = {
              if batteryTempStartMetric < 10 { return (Color.blue, "batteryblock.stack.badge.snowflake") }
              if batteryTempStartMetric < 50 { return (Color.green, "batteryblock.stack") }
              return (Color.red, "batteryblock.stack.trianglebadge.exclamationmark")
            }()
            let batteryTempStart = Measurement(value: batteryTempStartMetric, unit: UnitTemperature.celsius)
              .converted(to: model.appSettings.metric ? .celsius : .fahrenheit)
            GridValue(
              color: batteryTempStartColor,
              value: String(format: "%.0f", batteryTempStart.value),
              units: batteryTempStart.unit.symbol,
              symbolName: batteryTempStartIcon,
              title: "Start Temp"
            )
            
            let (batteryTempEndColor, batteryTempEndIcon) = {
              if batteryTempEndMetric < 10 { return (Color.blue, "batteryblock.stack.badge.snowflake") }
              if batteryTempEndMetric < 50 { return (Color.green,"batteryblock.stack") }
              return (Color.red, "batteryblock.stack.trianglebadge.exclamationmark")
            }()
            let batteryTempEnd = Measurement(value: batteryTempEndMetric, unit: UnitTemperature.celsius)
              .converted(to: model.appSettings.metric ? .celsius : .fahrenheit)
            GridValue(
              color: batteryTempEndColor,
              value: String(format: "%.0f", batteryTempEnd.value),
              units: batteryTempEnd.unit.symbol,
              symbolName: batteryTempEndIcon,
              title: "End Temp"
            )
          }
        }
      }
      Spacer()
    }
    .navigationTitle(Text("High Voltage Battery"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button("Done") { dismiss() }
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  @FetchAll var trips: [Trip]
  NavigationStack {
    TripDetailView(
      model: TripDetailModel(
        destination: .batteryChart,
        tripID: trips.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}

