import Foundation
import SwiftUI
import TipKit

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
    case rangeEfficiencyChart
    
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
      case .rangeEfficiencyChart:
        return "rangeConsumedChart"
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
        GridLocation(
          color: .purple,
          placeName: model.fromLocation.placeName,
          cityState: model.fromLocation.cityState,
          label: "From",
          symbolName: "mappin.and.ellipse.circle.fill"
        ) {
          model.destination = .editLocationForm(model.fromLocation)
        }
        
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
      
      if let weatherTemperatureStart = trip.weatherTempStart, let weatherTemperatureEnd = trip.weatherTempEnd,
         let weatherConditionsStart = trip.weatherConditionsStart, let weatherConditionsEnd = trip.weatherConditionsEnd {
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
      
      let duration: Duration = .seconds(trip.duration)
      let rawOdometer = Measurement(value: trip.odometerStart, unit: UnitLength.kilometers)
      let rawDistance = Measurement(value: trip.odometerEnd - trip.odometerStart, unit: UnitLength.kilometers)
      let rawAverageSpeed = Measurement(
        value: duration == .seconds(0) ? 0 : (rawDistance.value / Double(duration.components.seconds)) * 3600,
        unit: UnitSpeed.kilometersPerHour
      )
      let odometer = rawOdometer.converted(to: model.appSettings.metric ? .kilometers : .miles)
      let distance = rawDistance.converted(to: model.appSettings.metric ? .kilometers : .miles)
      let averageSpeed = rawAverageSpeed.converted(to: model.appSettings.metric ? .kilometersPerHour : .milesPerHour)
      
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
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

        if let energy = trip.energy {
          let energyUsed = Measurement(value: energy, unit: UnitEnergy.kilowattHours)
          let metricEfficiency = Measurement(
            value: energyUsed.value == 0.0 ? 0.0 : rawDistance.value / energyUsed.value,
            unit: UnitEnergyEfficiency.kilometersPerKilowattHour
          )
          let efficiency = metricEfficiency.converted(
            to: model.appSettings.metric ? model.appSettings.kWhPer100km ? .kilowattHoursPer100Kilometers : .kilometersPerKilowattHour : .milesPerKilowattHour
          )
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

        if let rawStateOfChargeEnd = trip.stateOfChargeEnd {
          let (stateOfChargeEndColor, stateOfChargeEndIcon) = {
            if rawStateOfChargeEnd < 5 { return (Color.red, "battery.0percent") }
            if rawStateOfChargeEnd < 30 { return (Color.yellow, "battery.25percent") }
            if rawStateOfChargeEnd < 55 { return (Color.green, "battery.50percent") }
            if rawStateOfChargeEnd < 80 { return (Color.green, "battery.75percent") }
            return (Color.green, "battery.100percent")
          }()
          let stateOfChargeEnd = Measurement(value: rawStateOfChargeEnd, unit: UnitPercent.percent)
          GridValueButton(
            color: stateOfChargeEndColor,
            value: String(format: "%.0f", stateOfChargeEnd.value),
            units: stateOfChargeEnd.unit.symbol,
            symbolName: stateOfChargeEndIcon,
            title: "State of Charge"
          ) {
            model.destination = .stateOfChargeChart
          }
        }

        if let rawBatteryTempEnd = trip.batteryTempEnd {
          let (batteryTempEndColor, batteryTempEndIcon) = {
            if rawBatteryTempEnd < 5 { return (Color.blue, "batteryblock.stack.badge.snowflake") }
            if rawBatteryTempEnd < 50 { return (Color.gray, "batteryblock.stack") }
            return (Color.red, "batteryblock.stack.trianglebadge.exclamationmark")
          }()
          let batteryTempEnd = Measurement(value: rawBatteryTempEnd, unit: UnitTemperature.celsius)
            .converted(to: model.appSettings.metric ? .celsius : .fahrenheit)
          GridValueButton(
            color: batteryTempEndColor,
            value: String(format: "%.0f", batteryTempEnd.value),
            units: batteryTempEnd.unit.symbol,
            symbolName: batteryTempEndIcon,
            title: "Temperature"
          ) {
            model.destination = .batteryTemperatureChart
          }
        }

        if let rawDistanceToEmptyStart = trip.distanceToEmptyStart, let rawDistanceToEmptyEnd = trip.distanceToEmptyEnd {
          let rangeConsumed = Measurement(value: rawDistanceToEmptyStart - rawDistanceToEmptyEnd, unit: UnitLength.kilometers)
            .converted(to: model.appSettings.metric ? .kilometers : .miles)
          let rangeEfficiency = distance - rangeConsumed
          GridValueButton(
            color: rangeEfficiency.value < 0 ? Color.orange : Color.blue,
            value: String(format: "%+.0f", rangeEfficiency.value),
            units: rangeEfficiency.unit.symbol,
            symbolName: "road.lanes.curved.right",
            title: "Range Efficiency"
          ) {
            model.destination = .rangeEfficiencyChart
          }
        }

        if let rawBatteryStateOfHealth = trip.batteryStateOfHealth {
          let batteryStateOfHealth = Measurement(value: rawBatteryStateOfHealth, unit: UnitPercent.percent)
          let batteryStateOfHealthColor = {
            if batteryStateOfHealth.value < 80 { return Color.red }
            if batteryStateOfHealth.value < 90 { return Color.yellow }
            return Color.green
          }()
          GridValueButton(
            color: batteryStateOfHealthColor,
            value: String(format: "%.0f", batteryStateOfHealth.value),
            units: batteryStateOfHealth.unit.symbol,
            symbolName: "batteryblock.stack.fill",
            title: "State of Health"
          ) {
            model.destination = .stateOfHealthChart
          }
        }
      }
      .padding([.bottom], 10)
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
          StateOfHealthHistoryView(
            model: StateOfHealthHistoryModel(
              vehicleID: trip.vehicleID,
              currentID: trip.id
            )
          )
          .presentationDetents([.medium])
        }
        
      case .rangeEfficiencyChart:
        NavigationStack {
          TripDetailRangeEfficiencyView(
            model: TripDetailRangeEfficiencyModel(
              trip: trip
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
    let _ = try? Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.applicationDefault)])
    TripDetailView(
      model: TripDetailModel(
        tripID: trips.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
