import Foundation
import SwiftUI
import TipKit

import DokoSharing
import DokoLocationManager
import DokoVehicleManager
import DokoSchema
import DokoTypes
import DokoExtensions
import VehiclesUI
import LocationsUI
import CommonUI

@MainActor @Observable public final class ChargeDetailModel {
  public enum Destination: Identifiable {
    case editChargeForm(Charge)
    case editLocationForm(Location)
    case editVehicleForm(Vehicle)
    case chargeLocationMap
    case powerChart
    case energyUsedChart
    case batteryChart
    case stateOfHealthChart

    public var id: String {
      switch self {
      case .editChargeForm(let charge):
        return "editChargeForm-\(charge.id)"
      case .editLocationForm(let location):
        return "editLocationForm-\(location.id)"
      case .editVehicleForm(let vehicle):
        return "editVehicleForm-\(vehicle.id)"
      case .chargeLocationMap:
        return "chargeLocationMap"
      case .powerChart:
        return "powerChart"
      case .energyUsedChart:
        return "energyUsedChart"
      case .batteryChart:
        return "batteryChart"
      case .stateOfHealthChart:
        return "stateOfHealthChart"
      }
    }
  }

  var destination: Destination?

  @ObservationIgnored @FetchOne(Charge.none) var charge
  @ObservationIgnored @FetchOne(ChargeHistory.none) var chargeHistory
  @ObservationIgnored @FetchAll var locations: [Location]
  @ObservationIgnored @Shared(.appSettings) var appSettings

  var chargeLocation: Location = .unexpectedLocation
  var vehicle: Vehicle?
  var maximumPower: Double?

  public init(
    destination: Destination? = nil,
    chargeID: Charge.ID
  ) {
    self.destination = destination
    _charge = FetchOne(Charge.find(chargeID))
    if let charge = self.charge {
      self.vehicle = DokoVehicleManager.shared.lookup(id: charge.vehicleID)
      self.chargeLocation = DokoLocationManager.shared.lookup(id: charge.locationID)
      _chargeHistory = FetchOne(ChargeHistory.find(charge.id))
      self.maximumPower = chargeHistory?.batteryPower.map(\.datapoint).max()
    }
  }
}

public struct ChargeDetailView: View {
  @Bindable var model: ChargeDetailModel

  public init(model: ChargeDetailModel) {
    self.model = model
  }

  public var body: some View {
    let charge = model.charge ?? Charge.honestEmptyCharge
    let duration: Duration = .seconds(charge.duration)
    let odometer = Measurement(value: charge.odometer, unit: UnitLength.kilometers)
      .converted(to: model.appSettings.metric ? .kilometers : .miles)
    let peakPower = Measurement(value: model.maximumPower ?? 0.0, unit: UnitPower.kilowatts)

    ScrollView {
      TipView(EditChargeDetailTip())
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          DokoGridButton(color: .blue, symbolName: "map.fill", title: "Map") {
            model.destination = .chargeLocationMap
          }

          DokoGridButton(
            color: .green,
            symbolName: "chart.xyaxis.line",
            title: "Power"
          ) {
            model.destination = .powerChart
          }

          DokoGridButton(
            color: .yellow,
            symbolName: "car",
            title: model.vehicle?.name ?? (model.vehicle?.model ?? "Missing Vehicle")
          ) {
            if let vehicle = model.vehicle {
              model.destination = .editVehicleForm(vehicle)
            }
          }
        }
      }

      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        Section {
          Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
              DokoGridLocation(
                color: charge.chargerType == .ac ? .purple : .green,
                placeName: model.chargeLocation.placeName,
                cityState: model.chargeLocation.cityState,
                label: charge.chargerType == .ac ? "AC" : "DCFC",
                symbolName: charge.chargerType == .ac ? "powerplug" : "ev.charger"
              ) {
                model.destination = .editLocationForm(model.chargeLocation)
              }
            }
          }
        }
      }
      
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          DokoGridCount(
            color: .yellow,
            value: String(format: "%.1f", odometer.value),
            units: odometer.unit.symbol,
            symbolName: "gauge.open.with.lines.needle.33percent",
            title: "Odometer"
          )

          DokoGridCount(
            color: .gray,
            value: duration.formatted(
              .time(pattern: .hourMinute(padHourToLength: 2))
            ),
            units: "hh:mm",
            symbolName: "clock",
            title: "Duration"
          )
        }

        if let energy = charge.energy {
          let energyAdded = Measurement(value: energy, unit: UnitEnergy.kilowattHours)
          let displayEnergy = abs(energyAdded.value) < 0.05 ? 0.0 : energyAdded.value
          GridRow {
            DokoGridValueButton(
              color: .blue,
              value: String(format: "%.1f", displayEnergy),
              units: energyAdded.unit.symbol,
              symbolName: "bolt.circle.fill",
              title: "Energy Added"
            ) {
              model.destination = .energyUsedChart
            }
            
            DokoGridCount(
              color: .red,
              value: String(format: "%.1f", peakPower.value),
              units: peakPower.unit.symbol,
              symbolName: "bolt",
              title: "Peak Power"
            )

          }
        }

        if let stateOfChargeStart = charge.stateOfChargeStart, let stateOfChargeEnd = charge.stateOfChargeEnd {
          GridRow {
            let stateOfChargeStart = Measurement(value: stateOfChargeStart, unit: UnitPercent.percent)
            let stateOfChargeEnd = Measurement(value: stateOfChargeEnd, unit: UnitPercent.percent)
            let (stateOfChargeStartColor, stateOfChargeStartIcon) = {
              if stateOfChargeStart.value < 25 { return (Color.red, "battery.25percent") }
              if stateOfChargeStart.value < 50 { return (Color.yellow,"battery.50percent") }
              return (Color.green, "battery.75percent")
            }()
            DokoGridCount(
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
            DokoGridCount(
              color: stateOfChargeEndColor,
              value: String(format: "%.0f", stateOfChargeEnd.value),
              units: stateOfChargeEnd.unit.symbol,
              symbolName: stateOfChargeEndIcon,
              title: "End SoC"
            )
          }
        }

        if let distanceToEmptyStart = charge.distanceToEmptyStart, let distanceToEmptyEnd = charge.distanceToEmptyEnd {
          GridRow {
            let dteStartMetric = Measurement(value: distanceToEmptyStart, unit: UnitLength.kilometers)
            let dteStart = dteStartMetric.converted(to: model.appSettings.metric ? .kilometers : .miles)
            DokoGridCount(
              color: .blue,
              value: String(format: "%.0f", dteStart.value),
              units: dteStart.unit.symbol,
              symbolName: "road.lanes.curved.left",
              title: "Start Range"
            )
            
            let dteEndMetric = Measurement(value: distanceToEmptyEnd, unit: UnitLength.kilometers)
            let dteEnd = dteEndMetric.converted(to: model.appSettings.metric ? .kilometers : .miles)
            DokoGridCount(
              color: .blue,
              value: String(format: "%.0f", dteEnd.value),
              units: dteEnd.unit.symbol,
              symbolName: "road.lanes.curved.right",
              title: "End Range"
            )
          }
        }

        if let batteryStateOfHealth = charge.batteryStateOfHealth {
          GridRow {
            let batteryStateOfHealth = Measurement(value: batteryStateOfHealth, unit: UnitPercent.percent)
            let batteryStateOfHealthColor =
            batteryStateOfHealth.value < 80 ? Color.red : batteryStateOfHealth.value < 90 ? .yellow : .green
            DokoGridValueButton(
              color: batteryStateOfHealthColor,
              value: String(format: "%.0f", batteryStateOfHealth.value),
              units: batteryStateOfHealth.unit.symbol,
              symbolName: "minus.plus.batteryblock.stack",
              title: "State of Health"
            ) {
              model.destination = .stateOfHealthChart
            }
            
            DokoGridValueButton(
              color: .orange,
              value: nil,
              units: nil,
              symbolName: "batteryblock.stack",
              title: "Battery Details"
            ) {
              model.destination = .batteryChart
            }
          }
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Edit") {
          model.destination = .editChargeForm(charge)
        }
      }
    }
    .navigationTitle(
      "\(charge.timeStart.formatted(date: .numeric, time: .shortened))"
    )
    .navigationBarTitleDisplayMode(.inline)
    .sheet(item: $model.destination) { destination in
      switch destination {
      case .editChargeForm(let charge):
        NavigationStack {
          ChargeFormView(
            model: ChargeFormModel(
              charge: Charge.Draft(charge)
            )
          )
          .navigationTitle("Edit Charge")
          .navigationBarTitleDisplayMode(.inline)
          .presentationDetents([.medium])
        }
      case .editLocationForm(let location):
        NavigationStack {
          LocationFormView(
            model: LocationFormModel(
              location: Location.Draft(location)
            )
          )
          .presentationDetents([.large])
        }
      case .editVehicleForm(let vehicle):
        NavigationStack {
          VehicleFormView(
            model: VehicleFormModel(
              vehicle: Vehicle.Draft(vehicle)
            )
          )
          .presentationDetents([.medium])
        }
      case .chargeLocationMap:
        NavigationStack {
          ChargeDetailMapView(
            model: ChargeDetailMapModel(
              charge: charge
            )
          )
          .presentationDetents([.large])
        }
      case .powerChart:
        NavigationStack {
          ChargeDetailPowerChartView(
            model: ChargeDetailPowerChartModel(
              charge: charge
            )
          )
          .presentationDetents([.medium])
        }
      case .energyUsedChart:
        NavigationStack {
          ChargeDetailEnergyView(
            model: ChargeDetailEnergyModel(
              charge: charge
            )
          )
          .presentationDetents([.medium])
        }
      case .batteryChart:
        NavigationStack {
          ChargeDetailBatteryView(
            model: ChargeDetailBatteryModel(
              charge: charge
            )
          )
          .presentationDetents([.medium])
        }
      case .stateOfHealthChart:
        NavigationStack {
          SoHHistoryView(
            model: SoHHistoryModel(
              vehicleID: charge.vehicleID,
              currentID: charge.id
            )
          )
          .presentationDetents([.medium])
        }
      }
    }
  }

}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  @FetchAll() var charges: [Charge]
  NavigationStack {
    let _ = try? Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.applicationDefault)])
    ChargeDetailView(
      model: ChargeDetailModel(
        chargeID: charges.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
