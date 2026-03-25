import Foundation
import SwiftUI
import MapKit

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
public final class TripDetailModel {
  public enum Destination: Identifiable {
    case editLocationForm(Location)
    case editVehicleForm(Vehicle)
    case tripMap
    case elevationChart
    case weatherChart
    case energyUsedChart
    case batteryChart
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
      case .batteryChart:
        return "batteryChart"
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
          DokoGridButton(
            color: .blue,
            iconName: "point.bottomleft.forward.to.point.topright.scurvepath.fill",
            title: "Route"
          ) {
            model.destination = .tripMap
          }
          
          DokoGridButton(
            color: .green,
            iconName: "mountain.2.fill",
            title: "Elevation"
          ) {
            model.destination = .elevationChart
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
      .padding([.bottom], 10)
      
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        Section {
          GridRow {
            DokoGridLocation(
              color: .purple,
              placeName: model.fromLocation.placeName,
              cityState: model.fromLocation.cityState,
              label: "From",
              iconName: "mappin.and.ellipse.circle.fill"
            ) {
              model.destination = .editLocationForm(model.fromLocation)
            }
          }
        }
        
        Section {
          GridRow {
            DokoGridLocation(
              color: .cyan,
              placeName: model.toLocation.placeName,
              cityState: model.toLocation.cityState,
              label: "To",
              iconName: "mappin.and.ellipse.circle.fill"
            ) {
              model.destination = .editLocationForm(model.toLocation)
            }
          }
        }
      }
      
      if let weatherTempStartMetric = trip.weatherTempStart, let weatherTempEndMetric = trip.weatherTempEnd,
         let weatherConditionsStart = trip.weatherConditionsStart, let weatherConditionsEnd = trip.weatherConditionsEnd {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
          GridRow {
            DokoGridWeatherConditions(
              startCondition: Measurement(value: weatherTempStartMetric, unit: UnitTemperature.celsius),
              startConditionSymbol: weatherConditionsStart,
              endCondition: Measurement(value: weatherTempEndMetric, unit: UnitTemperature.celsius),
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
      }
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          DokoGridCount(
            color: .blue,
            value: String(format: "%.1f", distance.value as CVarArg),
            units: distance.unit.symbol,
            iconName: "road.lanes",
            title: "Distance"
          )
          DokoGridCount(
            color: .orange,
            value: String(format: "%.0f", averageSpeed.value as CVarArg),
            units: averageSpeed.unit.symbol,
            iconName: "powermeter",
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
            DokoGridValueButton(
              color: .red,
              value: String(format: "%.1f", energyUsed.value as CVarArg),
              units: energyUsed.unit.symbol,
              iconName: "bolt.circle.fill",
              title: "Energy Used"
            ) {
              model.destination = .energyUsedChart
            }
            DokoGridCount(
              color: .green,
              value: String(format: "%.1f", efficiency.value as CVarArg),
              units: efficiency.unit.symbol,
              iconName: "ev.charger",
              title: "Efficiency"
            )
          }
        }
        
        if let distanceToEmptyStartMetric = trip.distanceToEmptyStart, let distanceToEmptyEndMetric = trip.distanceToEmptyEnd {
          GridRow {
            let distanceToEmptyStart = Measurement(value: distanceToEmptyStartMetric, unit: UnitLength.kilometers)
              .converted(to: model.appSettings.metric ? .kilometers : .miles)
            let distanceToEmptyEnd = Measurement(value: distanceToEmptyEndMetric, unit: UnitLength.kilometers)
              .converted(to: model.appSettings.metric ? .kilometers : .miles)
            DokoGridCount(
              color: .blue,
              value: String(format: "%.0f", distanceToEmptyStart.value as CVarArg),
              units: distanceToEmptyStart.unit.symbol,
              iconName: "road.lanes.curved.left",
              title: "Start Range"
            )
            DokoGridCount(
              color: .blue,
              value: String(format: "%.0f", distanceToEmptyEnd.value as CVarArg),
              units: distanceToEmptyEnd.unit.symbol,
              iconName: "road.lanes.curved.right",
              title: "End Range"
            )
          }
        }
        
        if let batteryStateOfHealth = trip.batteryStateOfHealth {
          let batteryStateOfHealthColor = {
            if batteryStateOfHealth < 80 { return Color.red }
            if batteryStateOfHealth < 90 { return Color.yellow }
            return Color.green
          }()
          GridRow {
            DokoGridValueButton(
              color: batteryStateOfHealthColor,
              value: String(format: "%.0f", batteryStateOfHealth),
              units: "%",
              iconName: "minus.plus.batteryblock.stack",
              title: "State of Health"
            ) {
              model.destination = .stateOfHealthChart
            }
            
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
      case .batteryChart:
        NavigationStack {
          TripDetailBatteryView(
            model: TripDetailBatteryModel(
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
