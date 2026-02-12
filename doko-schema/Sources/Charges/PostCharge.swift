import Foundation

import SQLiteData

import DokoTypes
import DokoLocationManager
import Vehicles
import Locations

extension Charge {
  public static func postChargeStartRecord(
    vehicleID: Vehicle.ID?,
    dcfcCharge: Bool,
    chargeStartResponse: DokoResponsePacket
  ) throws -> Charge.Draft {
    guard let vehicleID = vehicleID else { throw ChargeError.unknownVehicle }
    guard
      let position = chargeStartResponse.position,
      let odometer = chargeStartResponse.odometer
    else {
      throw ChargeError.chargeWriteError
    }
    guard let locationID = DokoLocationManager.shared.addLocation(
      latitude: position.latitude, longitude: position.longitude, elevation: position.elevation
    ) else { throw ChargeError.chargeLocationError }
    var charge = Charge(
      id: UUID(),
      vehicleID: vehicleID,
      locationID: locationID,
      latitude: position.latitude,
      longitude: position.longitude,
      elevation: position.elevation,
      timeStart: chargeStartResponse.completedAt,
      timeEnd: chargeStartResponse.completedAt,
      chargerType: dcfcCharge ? Charge.ChargerType.dc : Charge.ChargerType.ac,
      odometer: odometer,
    )
    charge.energyToEmptyStart = chargeStartResponse.energyToEmpty
    charge.energyToEmptyEnd = chargeStartResponse.energyToEmpty
    charge.energy = chargeStartResponse.batteryEnergy

    charge.distanceToEmptyStart = chargeStartResponse.distanceToEmpty
    charge.distanceToEmptyEnd = chargeStartResponse.distanceToEmpty
    if let _ = chargeStartResponse.distanceToEmpty {
      charge.range = 0.0
    }
    charge.stateOfChargeStart = chargeStartResponse.stateOfCharge
    charge.stateOfChargeEnd = chargeStartResponse.stateOfCharge
    charge.batteryStateOfHealth = chargeStartResponse.batteryStateOfHealth

    charge.batteryTempStart = chargeStartResponse.batteryTemperature
    charge.batteryTempEnd = chargeStartResponse.batteryTemperature

    charge.couplerTempStart = chargeStartResponse.couplerTemperature
    charge.couplerTempEnd = chargeStartResponse.couplerTemperature

    charge.weatherTempStart = chargeStartResponse.weather?.temperature
    charge.weatherConditionsStart = chargeStartResponse.weather?.conditionSymbol

    @Dependency(\.defaultDatabase) var database
    let chargeID: Charge.ID? = withErrorReporting {
      try database.write { db in
        let id = try Charge.upsert { charge }.returning(\.id).fetchOne(db)
        return id!
      }
    }
    guard let chargeID else { throw ChargeError.chargeWriteError }
    try? postChargeHistoryRecord(chargeID: chargeID, chargeHistoryPacket: chargeStartResponse)
    return Charge.Draft(charge)
  }

  public static func postChargeEndRecord(
    chargeDraft: Charge.Draft,
    chargeEndResponse: DokoResponsePacket
  ) throws {
    var chargeDraft = chargeDraft

    chargeDraft.timeEnd = chargeEndResponse.completedAt
    chargeDraft.duration = chargeEndResponse.completedAt.timeIntervalSince(chargeDraft.timeStart)
    
    chargeDraft.energyToEmptyEnd = chargeEndResponse.energyToEmpty
    chargeDraft.energy = chargeEndResponse.batteryEnergy

    chargeDraft.distanceToEmptyEnd = chargeEndResponse.distanceToEmpty
    if let dteStart = chargeDraft.distanceToEmptyStart, let dteEnd = chargeEndResponse.distanceToEmpty {
      chargeDraft.range = dteStart - dteEnd
    }

    chargeDraft.stateOfChargeEnd = chargeEndResponse.stateOfCharge
    chargeDraft.batteryTempEnd = chargeEndResponse.batteryTemperature
    chargeDraft.couplerTempEnd = chargeEndResponse.couplerTemperature

    @Dependency(\.defaultDatabase) var database
    withErrorReporting {
      try database.write { db in
        try Charge.upsert { chargeDraft }.fetchOne(db)
      }
    }
    guard let chargeID = chargeDraft.id else { throw ChargeError.chargeWriteError }
    try? postChargeHistoryRecord(chargeID: chargeID, chargeHistoryPacket: chargeEndResponse)
  }

  public static func postChargeUpdateRecord(
    chargeDraft: Charge.Draft,
    chargeUpdateResponse: DokoResponsePacket
  ) throws -> Charge.Draft {
    var chargeDraft = chargeDraft
    chargeDraft.timeEnd = chargeUpdateResponse.completedAt
    chargeDraft.duration = chargeUpdateResponse.completedAt.timeIntervalSince(chargeDraft.timeStart)

    chargeDraft.energy = chargeUpdateResponse.batteryEnergy
    chargeDraft.energyToEmptyEnd = chargeUpdateResponse.energyToEmpty

    chargeDraft.distanceToEmptyEnd = chargeUpdateResponse.distanceToEmpty
    if let dteStart = chargeDraft.energyToEmptyStart, let dteEnd = chargeUpdateResponse.distanceToEmpty {
      chargeDraft.range = dteStart - dteEnd
    }

    chargeDraft.stateOfChargeEnd = chargeUpdateResponse.stateOfCharge
    chargeDraft.batteryTempEnd = chargeUpdateResponse.batteryTemperature
    chargeDraft.couplerTempEnd = chargeUpdateResponse.couplerTemperature

    @Dependency(\.defaultDatabase) var database
    withErrorReporting {
      try database.write { db in
        try Charge.upsert { chargeDraft }.fetchOne(db)
      }
    }
    return chargeDraft
  }
}
