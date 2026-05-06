import Foundation

import SQLiteData

import DokoTypes
import DokoLocationManager
import Vehicles
import Locations

@DokoEngineActor
extension Trip {
  public static func postTripStartRecord(
    vehicleID: Vehicle.ID?,
    tripStartResponse: DokoResponsePacket
  ) throws -> Trip.Draft {
    guard let vehicleID = vehicleID else { throw TripError.unknownVehicle }
    guard
      let position = tripStartResponse.position,
      let odometer = tripStartResponse.odometer
    else {
      throw TripError.tripWriteError
    }

    guard let originID = DokoLocationManager.shared.addLocation(
      latitude: position.latitude, longitude: position.longitude, elevation: position.elevation, sharedLocation: true
    ) else { throw TripError.tripLocationError }
    guard let destinationID = DokoLocationManager.shared.addLocation(
      latitude: position.latitude, longitude: position.longitude, elevation: position.elevation, sharedLocation: false
    ) else { throw TripError.tripLocationError }

    var trip = Trip(
      id: UUID(),
      vehicleID: vehicleID,
      originID: originID,
      destinationID: destinationID,
      latitudeStart: position.latitude,
      longitudeStart: position.longitude,
      elevationStart: position.elevation,
      latitudeEnd: position.latitude,
      longitudeEnd: position.longitude,
      elevationEnd: position.elevation,
      timeStart: tripStartResponse.completedAt,
      timeEnd: tripStartResponse.completedAt,
      odometerStart: odometer,
      odometerEnd: odometer,
    )
    trip.energyToEmptyStart = tripStartResponse.batteryEnergyToEmpty
    trip.energyToEmptyEnd = tripStartResponse.batteryEnergyToEmpty
    trip.energy = tripStartResponse.batteryEnergy.map { -$0 }

    trip.distanceToEmptyStart = tripStartResponse.batteryDistanceToEmpty
    trip.distanceToEmptyEnd = tripStartResponse.batteryDistanceToEmpty
    trip.range = trip.distanceToEmptyStart.flatMap { start in trip.distanceToEmptyEnd.map { end in start - end } }

    trip.stateOfChargeStart = tripStartResponse.batteryStateOfCharge
    trip.stateOfChargeEnd = tripStartResponse.batteryStateOfCharge
    trip.batteryStateOfHealth = tripStartResponse.batteryStateOfHealth

    trip.batteryTempStart = tripStartResponse.batteryTemperature
    trip.batteryTempEnd = tripStartResponse.batteryTemperature

    trip.weatherTempStart = tripStartResponse.weather?.temperature
    trip.weatherTempEnd = tripStartResponse.weather?.temperature
    trip.weatherTempMeanWeighted = tripStartResponse.weather?.temperature
    trip.weatherConditionsStart = tripStartResponse.weather?.conditionSymbol
    trip.weatherConditionsEnd = tripStartResponse.weather?.conditionSymbol

    @Dependency(\.defaultDatabase) var database
    let tripID: Trip.ID? = withErrorReporting {
      try database.write { db in
        let id = try Trip.upsert { trip }.returning(\.id).fetchOne(db)
        return id!
      }
    }
    guard let tripID else { throw TripError.tripWriteError }
    try? postTripDataRecord(tripID: tripID, tripDataPacket: tripStartResponse)
    try? postTripWeatherRecord(tripID: tripID, tripWeatherPacket: tripStartResponse)
    try? postTripPositionRecord(tripID: tripID, tripPositionPacket: tripStartResponse)
    return Trip.Draft(trip)
  }

  public static func postTripEndRecord(
    tripDraft: Trip.Draft,
    tripEndResponse: DokoResponsePacket
  ) throws  -> Trip.Draft {
    guard
      let position = tripEndResponse.position,
      let odometer = tripEndResponse.odometer
    else {
      throw TripError.tripWriteError
    }
    var tripDraft = tripDraft

    tripDraft.destinationID = DokoLocationManager.shared.updateLocation(
      id: tripDraft.destinationID,
      latitude: position.latitude, longitude: position.longitude, elevation: position.elevation,
      sharedLocation: true
    )

    tripDraft.latitudeEnd = position.latitude
    tripDraft.longitudeEnd = position.longitude
    tripDraft.elevationEnd = position.elevation

    tripDraft.timeEnd = tripEndResponse.completedAt
    tripDraft.duration = tripEndResponse.completedAt.timeIntervalSince(tripDraft.timeStart)
    
    tripDraft.odometerEnd = odometer
    tripDraft.distance = odometer - tripDraft.odometerStart

    tripDraft.energyToEmptyEnd = tripEndResponse.batteryEnergyToEmpty
    tripDraft.energy = tripEndResponse.batteryEnergy.map { -$0 }

    tripDraft.distanceToEmptyEnd = tripEndResponse.batteryDistanceToEmpty
    tripDraft.range = tripDraft.distanceToEmptyStart.flatMap { start in tripEndResponse.batteryDistanceToEmpty.map { end in start - end } }

    tripDraft.stateOfChargeEnd = tripEndResponse.batteryStateOfCharge
    tripDraft.batteryStateOfHealth = tripEndResponse.batteryStateOfHealth
    tripDraft.batteryTempEnd = tripEndResponse.batteryTemperature

    tripDraft.weatherTempEnd = tripEndResponse.weather?.temperature
    tripDraft.weatherTempMeanWeighted = tripEndResponse.meanTemperature
    if let meanTemperature = tripEndResponse.meanTemperature {
      tripDraft.weatherTempMeanWeighted = meanTemperature * tripDraft.duration
    }
    tripDraft.weatherConditionsEnd = tripEndResponse.weather?.conditionSymbol

    @Dependency(\.defaultDatabase) var database
    withErrorReporting {
      try database.write { db in
        try Trip.upsert { tripDraft }.fetchOne(db)
      }
    }
    guard let tripID = tripDraft.id else {
      return tripDraft
    }
    try? postTripDataRecord(tripID: tripID, tripDataPacket: tripEndResponse)
    try? postTripWeatherRecord(tripID: tripID, tripWeatherPacket: tripEndResponse)
    try? postTripPositionRecord(tripID: tripID, tripPositionPacket: tripEndResponse)
    return tripDraft
  }

  public static func postTripUpdateRecord(
    tripDraft: Trip.Draft,
    tripUpdateResponse: DokoResponsePacket
  ) throws -> Trip.Draft {
    guard
      let position = tripUpdateResponse.position,
      let odometer = tripUpdateResponse.odometer
    else {
      throw TripError.tripUpdateError
    }
    var tripDraft = tripDraft

    tripDraft.destinationID = DokoLocationManager.shared.updateLocation(
      id: tripDraft.destinationID,
      latitude: position.latitude, longitude: position.longitude, elevation: position.elevation,
      sharedLocation: false
    )

    tripDraft.latitudeEnd = position.latitude
    tripDraft.longitudeEnd = position.longitude
    tripDraft.elevationEnd = position.elevation

    tripDraft.timeEnd = tripUpdateResponse.completedAt
    tripDraft.duration = tripUpdateResponse.completedAt.timeIntervalSince(tripDraft.timeStart)
    
    tripDraft.odometerEnd = odometer
    tripDraft.distance = odometer - tripDraft.odometerStart

    tripDraft.energyToEmptyEnd = tripUpdateResponse.batteryEnergyToEmpty
    tripDraft.energy = tripUpdateResponse.batteryEnergy.map { -$0 }

    tripDraft.distanceToEmptyEnd = tripUpdateResponse.batteryDistanceToEmpty
    tripDraft.range = tripDraft.distanceToEmptyStart.flatMap { start in tripUpdateResponse.batteryDistanceToEmpty.map { end in start - end } }
    
    tripDraft.stateOfChargeEnd = tripUpdateResponse.batteryStateOfCharge
    tripDraft.batteryTempEnd = tripUpdateResponse.batteryTemperature

    if let weather = tripUpdateResponse.weather {
      tripDraft.weatherTempEnd = weather.temperature
      tripDraft.weatherConditionsEnd = weather.conditionSymbol
      if tripDraft.weatherTempStart == nil {
        tripDraft.weatherTempStart = weather.temperature
      }
      if tripDraft.weatherConditionsStart == nil {
        tripDraft.weatherConditionsStart = weather.conditionSymbol
      }
    }

//###    @Dependency(\.defaultDatabase) var database
//    withErrorReporting {
//      try database.write { db in
//        try Trip.upsert { tripDraft }.fetchOne(db)
//      }
//    }
    return tripDraft
  }
}
