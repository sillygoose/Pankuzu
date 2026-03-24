import SwiftUI
import Charts

import DokoTypes
import DokoSharing
import DokoSchema
import CommonUI

@MainActor
@Observable
public final class ChargeDetailBatteryModel {
  var charge: Charge

  @ObservationIgnored
  @Shared(.metric) var metric
  
  public init(
    charge: Charge
  ) {
    self.charge = charge
  }
}

public struct ChargeDetailBatteryView: View {
  @Bindable var model: ChargeDetailBatteryModel
  @State private var showCouplerTempChart = false

  @Environment(\.dismiss) var dismiss

  public init(model: ChargeDetailBatteryModel) {
    self.model = model
  }

  public var body: some View {
    VStack {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
      if let stateOfChargeStart = model.charge.stateOfChargeStart, let stateOfChargeEnd = model.charge.stateOfChargeEnd {
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

      if let distanceToEmptyStart = model.charge.distanceToEmptyStart, let distanceToEmptyEnd = model.charge.distanceToEmptyEnd {
        GridRow {
          let dteStartMetric = Measurement(value: distanceToEmptyStart, unit: UnitLength.kilometers)
          let dteStart = dteStartMetric.converted(to: model.metric ? .kilometers : .miles)
          DokoGridCount(
            color: .blue,
            value: String(format: "%.0f", dteStart.value as CVarArg),
            units: dteStart.unit.symbol,
            iconName: "road.lanes.curved.left",
            title: "Start Range"
          )
          
          let dteEndMetric = Measurement(value: distanceToEmptyEnd, unit: UnitLength.kilometers)
          let dteEnd = dteEndMetric.converted(to: model.metric ? .kilometers : .miles)
          DokoGridCount(
            color: .blue,
            value: String(format: "%.0f", dteEnd.value as CVarArg),
            units: dteEnd.unit.symbol,
            iconName: "road.lanes.curved.right",
            title: "End Range"
          )
        }
      }

      if let energyToEmptyStart = model.charge.energyToEmptyStart, let energyToEmptyEnd = model.charge.energyToEmptyEnd {
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
              value: String(format: "%.1f", energyToEmptyEnd),
              units: "kWh",
              iconName: energyToEmptyEndIcon,
              title: "End Energy"
            )
          }
      }

      if let batteryTempStartMetric = model.charge.batteryTempStart, let batteryTempEndMetric = model.charge.batteryTempEnd {
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
      
        if let couplerTempStartMetric = model.charge.couplerTempStart, let couplerTempEndMetric = model.charge.couplerTempEnd {
          Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
              let (couplerTempStartColor, couplerTempStartIcon) = {
                if couplerTempStartMetric < 50 { return (Color.green, "ev.plug.dc.nacs") }
                return (Color.red, "ev.plug.dc.nacs")
              }()
              let couplerTempStart = Measurement(value: couplerTempStartMetric, unit: UnitTemperature.celsius)
                .converted(to: model.metric ? .celsius : .fahrenheit)
              DokoGridValueButton(
                color: couplerTempStartColor,
                value: String(format: "%.0f", couplerTempStart.value as CVarArg),
                units: couplerTempStart.unit.symbol,
                iconName: couplerTempStartIcon,
                title: "Coupler Start"
              ) {
                showCouplerTempChart = true
              }

              let (couplerTempEndColor, couplerTempEndIcon) = {
                if couplerTempEndMetric < 50 { return (Color.green, "ev.plug.dc.nacs") }
                return (Color.red, "ev.plug.dc.nacs")
              }()
              let couplerTempEnd = Measurement(value: couplerTempEndMetric, unit: UnitTemperature.celsius)
                .converted(to: model.metric ? .celsius : .fahrenheit)
              DokoGridValueButton(
                color: couplerTempEndColor,
                value: String(format: "%.0f", couplerTempEnd.value as CVarArg),
                units: couplerTempEnd.unit.symbol,
                iconName: couplerTempEndIcon,
                title: "Coupler End"
              ) {
                showCouplerTempChart = true
              }
            }
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
    .sheet(isPresented: $showCouplerTempChart) {
      NavigationStack {
        ChargeDetailCouplerTempChartView(
          model: ChargeDetailCouplerTempChartModel(
            charge: model.charge
          )
        )
        .presentationDetents([.medium])
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  @FetchAll var charges: [Charge]
  NavigationStack {
    ChargeDetailView(
      model: ChargeDetailModel(
        destination: .batteryChart,
        chargeID: charges.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}

