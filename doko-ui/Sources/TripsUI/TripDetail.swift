import Foundation
import SwiftUI
import MapKit

import Sharing

import DokoLiveActivityManager
import DokoLocationManager
import DokoVehicleManager
import DokoSchema
import DokoTypes
import DokoExtensions
import VehiclesUI
import LocationsUI
import CommonUI

@MainActor
@Observable
public final class TripDetailModel {
  public enum Destination: Identifiable {
    case editLocationForm(Location)
    case editVehicleForm(Vehicle)
    case tripMap
    case elevationChart
    case weatherChart
    case energyUsedChart
    case stateOfChargeChart
    case batteryTemperatureChart
    case stateOfHealthChart

    public var id: String {
      switch self {
      case .editLocationForm(let location):
        return "editLocationForm-\(location.id)"
      case .editVehicleForm(let vehicle):
        return "editVehicleForm-\(vehicle.id)"
      case .tripMap:
        return "tripMap"
      case .elevationChart:
        return "elevationChart"
      case .weatherChart:
        return "weatherChart"
      case .energyUsedChart:
        return "energyUsedChart"
      case .stateOfChargeChart:
        return "stateOfChargeChart"
      case .batteryTemperatureChart:
        return "batteryTemperatureChart"
      case .stateOfHealthChart:
        return "stateOfHealthChart"
      }
    }
  }

  var destination: Destination?

  @ObservationIgnored @FetchAll var locations: [Location]
  @ObservationIgnored @FetchOne(Trip.none) var trip
  @ObservationIgnored @Shared(.appSettings) var appSettings

  var vehicle: Vehicle?
  var fromLocation: Location = .unexpectedLocation
  var toLocation: Location = .unexpectedLocation

  public init(
    destination: Destination? = nil,
    tripID: Trip.ID
  ) {
    self.destination = destination
    _trip = FetchOne(Trip.find(tripID))
    if let trip = self.trip {
      self.vehicle = DokoVehicleManager.shared.lookup(id: trip.vehicleID)
      self.fromLocation = DokoLocationManager.shared.lookup(id: trip.originID)
      self.toLocation = DokoLocationManager.shared.lookup(id: trip.destinationID)
    }
  }
}

public struct TripDetailView: View {
  @Bindable var model: TripDetailModel

  public init(model: TripDetailModel) {
    self.model = model
  }

  public var body: some View {
    let trip = model.trip ?? Trip.honestEmptyTrip

    ScrollView {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          GridButton(
            color: .blue,
            symbolName: "point.bottomleft.forward.to.point.topright.scurvepath.fill",
            title: "Route"
          ) {
            model.destination = .tripMap
          }

          GridButton(
            color: .green,
            symbolName: "mountain.2.fill",
            title: "Elevation"
          ) {
            model.destination = .elevationChart
          }

          GridButton(
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
      .padding([.bottom], 10)

      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        Section {
          GridRow {
            GridLocation(
              color: .purple,
              placeName: model.fromLocation.placeName,
              cityState: model.fromLocation.cityState,
              label: "From",
              symbolName: "mappin.and.ellipse.circle.fill"
            ) {
              model.destination = .editLocationForm(model.fromLocation)
            }
          }
        }

        Section {
          GridRow {
            GridLocation(
              color: .cyan,
              placeName: model.toLocation.placeName,
              cityState: model.toLocation.cityState,
              label: "To",
              symbolName: "mappin.and.ellipse.circle.fill"
            ) {
              model.destination = .editLocationForm(model.toLocation)
            }
          }
        }
      }

      if let weatherTemperatureStart = trip.weatherTempStart, let weatherTemperatureEnd = trip.weatherTempEnd,
         let weatherConditionsStart = trip.weatherConditionsStart, let weatherConditionsEnd = trip.weatherConditionsEnd {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
          GridRow {
            GridWeatherConditions(
              startTemperature: weatherTemperatureStart,
              startConditionSymbol: weatherConditionsStart,
              endTemperature: weatherTemperatureEnd,
              endConditionSymbol: weatherConditionsEnd,
              title: "Trip Conditions"
            ) {
              model.destination = .weatherChart
            }
          }
        }
      }

      let duration: Duration = .seconds(trip.duration)
      let metricOdometer = Measurement(value: trip.odometerStart, unit: UnitLength.kilometers)
      let metricDistance = Measurement(value: trip.odometerEnd - trip.odometerStart, unit: UnitLength.kilometers)
      let metricAverageSpeed = Measurement(
        value: duration == .seconds(0) ? 0 : (metricDistance.value / Double(duration.components.seconds)) * 3600,
        unit: UnitSpeed.kilometersPerHour
      )
      let odometer = metricOdometer.converted(to: model.appSettings.metric ? .kilometers : .miles)
      let distance = metricDistance.converted(to: model.appSettings.metric ? .kilometers : .miles)
      let averageSpeed = metricAverageSpeed.converted(to: model.appSettings.metric ? .kilometersPerHour : .milesPerHour)

      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          GridValue(
            color: .yellow,
            value: String(format: "%.1f", odometer.value),
            units: odometer.unit.symbol,
            symbolName: "gauge.open.with.lines.needle.33percent",
            title: "Odometer"
          )
          GridValue(
            color: .gray,
            value: duration.formatted(
              .time(pattern: .hourMinute(padHourToLength: 2))
            ),
            units: "hh:mm",
            symbolName: "clock",
            title: "Duration"
          )
        }
      }

      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          GridValue(
            color: .blue,
            value: String(format: "%.1f", distance.value),
            units: distance.unit.symbol,
            symbolName: "road.lanes",
            title: "Distance"
          )
          GridValue(
            color: .orange,
            value: String(format: "%.0f", averageSpeed.value),
            units: averageSpeed.unit.symbol,
            symbolName: "powermeter",
            title: "Speed"
          )
        }
      }

      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        if let energy = trip.energy {
          let energyUsed = Measurement(value: energy, unit: UnitEnergy.kilowattHours)
          let metricEfficiency = Measurement(
            value: energyUsed.value == 0.0 ? 0.0 : metricDistance.value / energyUsed.value,
            unit: UnitEnergyEfficiency.kilometersPerKilowattHour
          )
          let efficiency = metricEfficiency
            .converted(
              to:model.appSettings.metric ? model.appSettings.kWhPer100km ? .kilowattHoursPer100Kilometers : .kilometersPerKilowattHour : .milesPerKilowattHour
            )
          GridRow {
            GridValueButton(
              color: .red,
              value: String(format: "%.1f", energyUsed.value),
              units: energyUsed.unit.symbol,
              symbolName: "bolt.circle.fill",
              title: "Energy Used"
            ) {
              model.destination = .energyUsedChart
            }
            GridValue(
              color: .green,
              value: String(format: "%.1f", efficiency.value),
              units: efficiency.unit.symbol,
              symbolName: "ev.charger",
              title: "Efficiency"
            )
          }
        }

        if let rawStateOfChargeStart = trip.stateOfChargeStart, let rawStateOfChargeEnd = trip.stateOfChargeEnd {
          let (stateOfChargeStartColor, stateOfChargeStartIcon) = {
            if rawStateOfChargeStart < 10 { return (Color.red, "battery.25percent") }
            if rawStateOfChargeStart < 25 { return (Color.yellow,"battery.50percent") }
            return (Color.green, "battery.75percent")
          }()
          let (stateOfChargeEndColor, stateOfChargeEndIcon) = {
            if rawStateOfChargeEnd < 10 { return (Color.red, "battery.25percent") }
            if rawStateOfChargeEnd < 25 { return (Color.yellow,"battery.50percent") }
            return (Color.green, "battery.75percent")
          }()
          let stateOfChargeStart = Measurement(value: rawStateOfChargeStart, unit: UnitPercent.percent)
          let stateOfChargeEnd = Measurement(value: rawStateOfChargeEnd, unit: UnitPercent.percent)
          GridRangeButton(
            rangeName: "State Of Charge",
            startValue: String(format: "%.0f", stateOfChargeStart.value),
            startUnit: stateOfChargeStart.unit.symbol,
            startColor: stateOfChargeStartColor,
            startSymbol: stateOfChargeStartIcon,
            endValue: String(format: "%.0f", stateOfChargeEnd.value),
            endUnit: stateOfChargeEnd.unit.symbol,
            endColor: stateOfChargeEndColor,
            endSymbol: stateOfChargeEndIcon,
          ) {
            model.destination = .stateOfChargeChart
          }
        }

        if let distanceToEmptyStartRaw = trip.distanceToEmptyStart, let distanceToEmptyEndRaw = trip.distanceToEmptyEnd {
          let (distanceToEmptyStartColor, distanceToEmptyStartStartIcon) = {
            if distanceToEmptyStartRaw < 35 { return (Color.red, "road.lanes.curved.left") }
            if distanceToEmptyStartRaw < 70 { return (Color.yellow,"road.lanes.curved.left") }
            return (Color.green, "road.lanes.curved.left")
          }()
          let (distanceToEmptyEndColor, distanceToEmptyEndIcon) = {
            if distanceToEmptyEndRaw < 35 { return (Color.red, "road.lanes.curved.right") }
            if distanceToEmptyEndRaw < 70 { return (Color.yellow,"road.lanes.curved.right") }
            return (Color.green, "road.lanes.curved.right")
          }()
          let distanceToEmptyStart = Measurement(value: distanceToEmptyStartRaw, unit: UnitLength.kilometers)
            .converted(to: model.appSettings.metric ? .kilometers : .miles)
          let distanceToEmptyEnd = Measurement(value: distanceToEmptyEndRaw, unit: UnitLength.kilometers)
            .converted(to: model.appSettings.metric ? .kilometers : .miles)
          GridRangeButton(
            rangeName: "Distance To Empty",
            startValue: String(format: "%.0f", distanceToEmptyStart.value),
            startUnit: distanceToEmptyStart.unit.symbol,
            startColor: distanceToEmptyStartColor,
            startSymbol: distanceToEmptyStartStartIcon,
            endValue: String(format: "%.0f", distanceToEmptyEnd.value),
            endUnit: distanceToEmptyEnd.unit.symbol,
            endColor: distanceToEmptyEndColor,
            endSymbol: distanceToEmptyEndIcon,
          ) {
            //###
          }
        }

        if let rawBatteryTempStart = trip.batteryTempStart, let rawBatteryTempEnd = trip.batteryTempEnd {
          let (batteryTempStartColor, batteryTempStartIcon) = {
            if rawBatteryTempStart < 10 { return (Color.blue, "batteryblock.stack.badge.snowflake") }
            if rawBatteryTempStart < 50 { return (Color.green, "batteryblock.stack") }
            return (Color.red, "batteryblock.stack.trianglebadge.exclamationmark")
          }()
          let (batteryTempEndColor, batteryTempEndIcon) = {
            if rawBatteryTempEnd < 10 { return (Color.blue, "batteryblock.stack.badge.snowflake") }
            if rawBatteryTempEnd < 50 { return (Color.green,"batteryblock.stack") }
            return (Color.red, "batteryblock.stack.trianglebadge.exclamationmark")
          }()
          let batteryTempStart = Measurement(value: rawBatteryTempStart, unit: UnitTemperature.celsius)
            .converted(to: model.appSettings.metric ? .celsius : .fahrenheit)
          let batteryTempEnd = Measurement(value: rawBatteryTempEnd, unit: UnitTemperature.celsius)
            .converted(to: model.appSettings.metric ? .celsius : .fahrenheit)
          GridRangeButton(
            rangeName: "Battery Temperature",
            startValue: String(format: "%.0f", batteryTempStart.value),
            startUnit: batteryTempStart.unit.symbol,
            startColor: batteryTempStartColor,
            startSymbol: batteryTempStartIcon,
            endValue: String(format: "%.0f", batteryTempEnd.value),
            endUnit: batteryTempEnd.unit.symbol,
            endColor: batteryTempEndColor,
            endSymbol: batteryTempEndIcon,
          ) {
            model.destination = .batteryTemperatureChart
          }
        }

        if let batteryStateOfHealth = trip.batteryStateOfHealth {
          let batteryStateOfHealth = Measurement(value: batteryStateOfHealth, unit: UnitPercent.percent)
          let batteryStateOfHealthColor = {
            if batteryStateOfHealth.value < 80 { return Color.red }
            if batteryStateOfHealth.value < 90 { return Color.yellow }
            return Color.green
          }()
          GridRow {
            GridValueButton(
              color: batteryStateOfHealthColor,
              value: String(format: "%.0f", batteryStateOfHealth.value),
              units: batteryStateOfHealth.unit.symbol,
              symbolName: "minus.plus.batteryblock.stack",
              title: "State of Health"
            ) {
              model.destination = .stateOfHealthChart
            }
          }
        }
      }
    }
    .navigationTitle(
      "\(trip.timeStart.formatted(date: .numeric, time: .shortened))"
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
        
      case .tripMap:
        NavigationStack {
          TripDetailMapView(
            model: TripDetailMapModel(
              trip: trip
            )
          )
          .presentationDetents([.large])
        }
        
      case .elevationChart:
        NavigationStack {
          TripDetailElevationView(
            model: TripDetailElevationModel(
              trip: trip
            )
          )
          .presentationDetents([.medium])
        }
        
      case .weatherChart:
        NavigationStack {
          TripDetailWeatherView(
            model: TripDetailWeatherModel(
              trip: trip
            )
          )
          .presentationDetents([.large])
        }
      case .energyUsedChart:
        NavigationStack {
          TripDetailEnergyView(
            model: TripDetailEnergyModel(
              trip: trip
            )
          )
          .presentationDetents([.medium])
        }
        
      case .stateOfChargeChart:
        NavigationStack {
          TripDetailStateOfChargeView(
            model: TripDetailStateOfChargeModel(
              trip: trip
            )
          )
          .presentationDetents([.medium])
        }
        
      case .batteryTemperatureChart:
        NavigationStack {
          TripDetailBatteryTemperatureView(
            model: TripDetailBatteryTemperatureModel(
              trip: trip
            )
          )
          .presentationDetents([.medium])
        }
        
      case .stateOfHealthChart:
        NavigationStack {
          SoHHistoryView(
            model: SoHHistoryModel(
              vehicleID: trip.vehicleID,
              currentID: trip.id
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
  @FetchAll() var trips: [Trip]
  NavigationStack {
    TripDetailView(
      model: TripDetailModel(
        tripID: trips.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
