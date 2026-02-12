import Foundation
import MapKit
import SwiftUI

import Sharing

import DokoLocationManager
import DokoVehicleManager
import DokoSchema
import DokoTypes
import VehiclesUI
import LocationsUI
import CommonUI

@MainActor
@Observable
public final class ChargeDetailModel {
  public enum Destination: Identifiable {
    case editLocationForm(Location)
    case editVehicleForm(Vehicle)
    case chargeLocationMap
    case powerChart
    case energyUsedChart
    case batteryChart

    public var id: String {
      switch self {
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
      }
    }
  }

  var destination: Destination?

  @ObservationIgnored
  @FetchOne(Charge.none) var charge

  @ObservationIgnored
  @FetchOne(ChargeHistory.none) var chargeHistory

  @ObservationIgnored
  @FetchAll var locations: [Location]

  @ObservationIgnored
  @Shared(.metric) var metric

  var chargeLocation: Location?
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
      .converted(to: model.metric ? .kilometers : .miles)
    let peakPower = Measurement(value: model.maximumPower ?? 0.0, unit: UnitPower.kilowatts)

    ScrollView {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          DokoGridButton(color: .blue, iconName: "map.fill", title: "Map") {
            model.destination = .chargeLocationMap
          }

          DokoGridButton(
            color: .green,
            iconName: "chart.xyaxis.line",
            title: "Power"
          ) {
            model.destination = .powerChart
          }

          DokoGridButton(
            color: .yellow,
            iconName: "car",
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
              let (placeName, cityState) = {
                guard let chargeLocation = model.chargeLocation else { return ("In Progress", "") }
                return (chargeLocation.placeName, chargeLocation.cityState)
              }()
              DokoGridLocation(
                color: charge.chargerType == .ac ? .purple : .green,
                placeName: placeName,
                cityState: cityState,
                label: charge.chargerType == .ac ? "AC" : "DCFC",
                iconName: charge.chargerType == .ac ? "powerplug" : "ev.charger"
              ) {
                if let chargeLocation = model.chargeLocation {
                  model.destination = .editLocationForm(chargeLocation)
                }
              }
            }
          }
        }
      }
      
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          DokoGridCount(
            color: .yellow,
            value: String(format: "%.1f", odometer.value as CVarArg),
            units: odometer.unit.symbol,
            iconName: "gauge.open.with.lines.needle.33percent",
            title: "Odometer"
          )

          DokoGridCount(
            color: .gray,
            value: duration.formatted(
              .time(pattern: .hourMinute(padHourToLength: 2))
            ),
            units: "hh:mm",
            iconName: "clock",
            title: "Duration"
          )
        }

        if let energy = charge.energy {
          let energyAdded = Measurement(value: energy, unit: UnitEnergy.kilowattHours)
          let displayEnergy = abs(energyAdded.value) < 0.05 ? 0.0 : energyAdded.value
          GridRow {
            DokoGridValueButton(
              color: .blue,
              value: String(format: "%.1f", displayEnergy as CVarArg),
              units: energyAdded.unit.symbol,
              iconName: "bolt.circle.fill",
              title: "Energy Added"
            ) {
              model.destination = .energyUsedChart
            }
            
            DokoGridCount(
              color: .red,
              value: String(format: "%.1f", peakPower.value as CVarArg),
              units: peakPower.unit.symbol,
              iconName: "bolt",
              title: "Peak Power"
            )

          }
        }

        if let stateOfChargeStart = charge.stateOfChargeStart, let stateOfChargeEnd = charge.stateOfChargeEnd {
          GridRow {
            let (stateOfChargeStartColor, stateOfChargeStartIcon) = {
              if stateOfChargeStart < 25 { return (Color.red, "battery.25percent") }
              if stateOfChargeStart < 50 { return (Color.yellow,"battery.50percent") }
              return (Color.green, "battery.75percent")
            }()
            DokoGridCount(
              color: stateOfChargeStartColor,
              value: String(format: "%.1f", stateOfChargeStart),
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
              value: String(format: "%.1f", stateOfChargeEnd),
              units: "%",
              iconName: stateOfChargeEndIcon,
              title: "End SoC"
            )
          }
        }

        if let distanceToEmptyStart = charge.distanceToEmptyStart, let distanceToEmptyEnd = charge.distanceToEmptyEnd {
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

        if let batteryStateOfHealth = charge.batteryStateOfHealth {
          GridRow {
            let batteryStateOfHealthColor =
            batteryStateOfHealth < 80 ? Color.red : batteryStateOfHealth < 90 ? .yellow : .green
            DokoGridCount(
              color: batteryStateOfHealthColor,
              value: String(format: "%.1f", batteryStateOfHealth),
              units: "%",
              iconName: "minus.plus.batteryblock.stack",
              title: "State of Health"
            )
            
            DokoGridValueButton(
              color: .orange,
              value: nil,
              units: nil,
              iconName: "batteryblock.stack",
              title: "Battery Details"
            ) {
              model.destination = .batteryChart
            }
          }
        }
      }
    }
    .navigationTitle(
      "\(charge.timeStart.formatted(date: .numeric, time: .shortened))"
    )
    .navigationBarTitleDisplayMode(.inline)
    .sheet(item: $model.destination) { destination in
      switch destination {
      case .editLocationForm(let location):
        NavigationStack {
          LocationFormView(
            model: LocationFormModel(
              location: Location.Draft(location)
            )
          )
          .presentationDetents([.medium])
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
    ChargeDetailView(
      model: ChargeDetailModel(
        chargeID: charges.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
