import Foundation

import DokoSchema
import DokoVehicleManager
import DokoLocationManager

extension DatabaseSeedingModel {
  static private let f150Vin: String = "1FTVW3L76SWG00000"
  
  func tripPositions(_ tripStart: Date) -> [VehiclePosition] {
    let tripPositions: [VehiclePosition] = [
      VehiclePosition(timestamp: tripStart.addingTimeInterval(0), latitude: 42.947846, longitude: -76.428322, elevation: 267.4),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(34), latitude: 42.947053, longitude: -76.4281051, elevation: 266.4),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(44), latitude: 42.947029, longitude: -76.4275970, elevation: 267.9),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(47), latitude: 42.947005, longitude: -76.4275074, elevation: 268.2),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(50), latitude: 42.946865, longitude: -76.4275283, elevation: 268.5),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(93), latitude: 42.945709, longitude: -76.4278335, elevation: 269.4),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(96), latitude: 42.945632, longitude: -76.4277191, elevation: 270.4),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(112), latitude: 42.945397, longitude: -76.425727, elevation: 269.7),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(124), latitude: 42.945201, longitude: -76.424240, elevation: 270.7),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(137), latitude: 42.944911, longitude: -76.421997, elevation: 280.1),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(146), latitude: 42.944728, longitude: -76.420509, elevation: 283.8),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(152), latitude: 42.944599, longitude: -76.419425, elevation: 285),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(165), latitude: 42.944313, longitude: -76.416984, elevation: 291.1),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(167), latitude: 42.944290, longitude: -76.416641, elevation: 292.9),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(174), latitude: 42.944271, longitude: -76.416168, elevation: 296.6),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(198), latitude: 42.944362, longitude: -76.414337, elevation: 300.5),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(233), latitude: 42.944602, longitude: -76.409858, elevation: 293.2),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(236), latitude: 42.944596, longitude: -76.409786, elevation: 293.2),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(239), latitude: 42.944744, longitude: -76.409683, elevation: 293.5),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(242), latitude: 42.944839, longitude: -76.409721, elevation: 293.5),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(245), latitude: 42.944908, longitude: -76.409538, elevation: 293.5),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(249), latitude: 42.944915, longitude: -76.409439, elevation: 293.5),
      VehiclePosition(timestamp: tripStart.addingTimeInterval(252), latitude: 42.944915, longitude: -76.409439, elevation: 293.8),
    ]
    return tripPositions
  }

  func tripElevations(_ tripStart: Date) -> [VehicleElevation] {
    let tripElevations: [VehicleElevation] = [
      VehicleElevation(timestamp: tripStart.addingTimeInterval(0), elevation: 267.4),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(34), elevation: 266.4),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(44), elevation: 267.9),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(47), elevation: 268.2),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(50), elevation: 268.5),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(93), elevation: 269.4),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(96), elevation: 270.4),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(112), elevation: 269.7),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(124), elevation: 270.7),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(137), elevation: 280.1),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(146), elevation: 283.8),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(152), elevation: 285),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(165), elevation: 291.1),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(167), elevation: 292.9),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(174), elevation: 296.6),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(198), elevation: 300.5),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(233), elevation: 293.2),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(236), elevation: 293.2),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(239), elevation: 293.5),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(242), elevation: 293.5),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(245), elevation: 293.5),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(249), elevation: 293.5),
      VehicleElevation(timestamp: tripStart.addingTimeInterval(252), elevation: 293.8),
    ]
    return tripElevations
  }

  func tripBatteryEnergy(_ tripStart: Date) -> [DokoDataPoint] {
    let tripBatteryEnergy: [DokoDataPoint] = [
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(0), double: 0.0),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(30), double: -0.074),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(60), double: -0.094),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(90), double: -0.06),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(120), double: -0.178),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(150), double: -0.156),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(180), double: -0.01),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(210), double: -0.054),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(240), double: 0.046),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(255), double: -0.008),
    ]
    return tripBatteryEnergy
  }
  
  func tripEnergyToEmpty(_ tripStart: Date) -> [DokoDataPoint] {
    let tripEnergyToEmpty: [DokoDataPoint] = [
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(0), double: 82.64),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(30), double: 82.566),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(60), double: 82.472),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(90), double: 82.412),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(120), double: 82.234),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(150), double: 82.078),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(180), double: 82.068),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(210), double: 82.014),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(240), double: 82.06),
      DokoDataPoint(timestamp: tripStart.addingTimeInterval(255), double: 82.052),
    ]
    return tripEnergyToEmpty
  }
  
  func tripWeather(_ tripStart: Date) -> [DokoWeather] {
    let tripWeather: [DokoWeather] = [
      DokoWeather(timestamp: tripStart, temperature: -13, windSpeed: 5, windGust: 10, windDirection: 246, windCompassDirection: "WSW", conditionSymbol: "cloud"),
      DokoWeather(timestamp: tripStart.addingTimeInterval(255), temperature: -13, windSpeed: 5, windGust: 11, windDirection: 247, windCompassDirection: "WSW", conditionSymbol: "cloud")
    ]
    return tripWeather
  }
}

extension DatabaseSeedingModel {
  public func seedTrip(tripStart: Date) {
    let vehicleID = DokoVehicleManager.shared.addVehicle(newVehicle: Vehicle(vin: DatabaseSeedingModel.f150Vin, name: "Example F-150"))
    let originID = DokoLocationManager.shared.addLocation(latitude: 42.947846, longitude: -76.428322, elevation: 266.4)
    let destinationID = DokoLocationManager.shared.addLocation(latitude: 42.944915, longitude: -76.409439, elevation: 293.8)
    guard let vehicleID, let originID, let destinationID else {
      return
    }

    let trip = Trip.Draft(
      deleted: nil,
      vehicleID: vehicleID,
      originID: originID,
      destinationID: destinationID,
      latitudeStart: 42.947846,
      longitudeStart: -76.428322,
      elevationStart: 267.424406,
      latitudeEnd: 42.944915,
      longitudeEnd: -76.409439,
      elevationEnd: 293.8,
      timeStart: tripStart,
      timeEnd: tripStart.addingTimeInterval(255),
      duration: 255,
      odometerStart: 13501.1,
      odometerEnd: 13502.9,
      distance: 1.8,
      energyToEmptyStart: 82.64,
      energyToEmptyEnd: 82.052,
      energy: 0.588,
      distanceToEmptyStart: 400.6,
      distanceToEmptyEnd: 397.1,
      range: 3.5,
      stateOfChargeStart: 98,
      stateOfChargeEnd: 97,
      batteryStateOfHealth: 100,
      batteryTempStart: -11,
      batteryTempEnd: -10,
      weatherTempStart: -13.38,
      weatherTempEnd: -13.27,
      weatherTempMeanWeighted: -3371.03,
      weatherConditionsStart: "cloud",
      weatherConditionsEnd: "cloud",
    )

    @Dependency(\.defaultDatabase) var database
    let tripID: Trip.ID? = withErrorReporting {
      try database.write { db in
        let id = try Trip.upsert { trip }.returning(\.id).fetchOne(db)
        return id!
      }
    }
    guard let tripID else {
      return
    }

    let tripPositions = TripPosition(tripID: tripID, path: tripPositions(tripStart))
    let tripElevations = TripElevation(tripID: tripID, elevations: tripElevations(tripStart))
    let tripData = TripData(
      tripID: tripID,
      batteryEnergy: tripBatteryEnergy(tripStart),
      energyToEmpty: tripEnergyToEmpty(tripStart)
    )
    let tripWeather = TripWeather(tripID: tripID, weather: tripWeather(tripStart))
    withErrorReporting {
      try database.write { db in
        try TripPosition.upsert { tripPositions }.execute(db)
        try TripElevation.upsert { tripElevations }.execute(db)
        try TripData.upsert { tripData }.execute(db)
        try TripWeather.upsert { tripWeather }.execute(db)
      }
    }
  }
}
