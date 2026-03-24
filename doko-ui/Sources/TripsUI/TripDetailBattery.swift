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
  @Shared(.metric) var metric
  
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
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
          GridRow {
            let (stateOfChargeStartColor, stateOfChargeStartIcon) = {
              if stateOfChargeStart < 25 { return (Color.red, "battery.25percent") }
              if stateOfChargeStart < 50 { return (Color.yellow,"battery.50percent") }
              return (Color.green, "battery.75percent")
            }()
            DokoGridCount(
              color: stateOfChargeStartColor,
              value: String(format: "%.0f", stateOfChargeStart),
              units: "%",
              iconName: stateOfChargeStartIcon,
              title: "Start SoC"
            )
            let (stateOfChargeEndColor, stateOfChargeEndIcon) = {
              if stateOfChargeEnd < 25 { return (Color.red, "battery.25percent") }
              if stateOfChargeEnd < 50 { return (Color.yellow,"battery.50percent") }
              return (Color.green, "battery.75percent")
            }()
            DokoGridCount(
              color: stateOfChargeEndColor,
              value: String(format: "%.0f", stateOfChargeEnd),
              units: "%",
              iconName: stateOfChargeEndIcon,
              title: "End SoC"
            )
          }
        }
      }
 
      if let energyToEmptyStart = model.trip.energyToEmptyStart, let energyToEmptyEnd = model.trip.energy {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
          GridRow {
            let (energyToEmptyStartColor, energyToEmptyStartIcon) = {
              if energyToEmptyStart < 25 { return (Color.red, "bolt") }
              if energyToEmptyStart < 50 { return (Color.yellow,"bolt") }
              return (Color.green, "bolt")
            }()
            DokoGridCount(
              color: energyToEmptyStartColor,
              value: String(format: "%.1f", energyToEmptyStart),
              units: "kWh",
              iconName: energyToEmptyStartIcon,
              title: "Start Energy"
            )

            let (energyToEmptyEndColor, energyToEmptyEndIcon) = {
              if energyToEmptyEnd < 25 { return (Color.red, "bolt") }
              if energyToEmptyEnd < 50 { return (Color.yellow,"bolt") }
              return (Color.green, "bolt")
            }()
            DokoGridCount(
              color: energyToEmptyEndColor,
              value: String(format: "%.1f", energyToEmptyStart - energyToEmptyEnd),
              units: "kWh",
              iconName: energyToEmptyEndIcon,
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
              .converted(to: model.metric ? .celsius : .fahrenheit)
            DokoGridCount(
              color: batteryTempStartColor,
              value: String(format: "%.0f", batteryTempStart.value as CVarArg),
              units: batteryTempStart.unit.symbol,
              iconName: batteryTempStartIcon,
              title: "Start Temp"
            )
            
            let (batteryTempEndColor, batteryTempEndIcon) = {
              if batteryTempEndMetric < 10 { return (Color.blue, "batteryblock.stack.badge.snowflake") }
              if batteryTempEndMetric < 50 { return (Color.green,"batteryblock.stack") }
              return (Color.red, "batteryblock.stack.trianglebadge.exclamationmark")
            }()
            let batteryTempEnd = Measurement(value: batteryTempEndMetric, unit: UnitTemperature.celsius)
              .converted(to: model.metric ? .celsius : .fahrenheit)
            DokoGridCount(
              color: batteryTempEndColor,
              value: String(format: "%.0f", batteryTempEnd.value as CVarArg),
              units: batteryTempEnd.unit.symbol,
              iconName: batteryTempEndIcon,
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

