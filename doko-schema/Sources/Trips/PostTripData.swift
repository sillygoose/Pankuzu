import Foundation
import OSLog

import SQLiteData

import DokoTypes
import DokoLogging
import DokoSchemaTypes

@DokoEngineActor
extension Trip {
  public static func postTripData(
    tripID: Trip.ID,
    tripDataPacket: DokoResponsePacket
  ) throws {
    guard
      let odometer = tripDataPacket.odometer
    else {
      throw TripError.tripDataArgumentError
    }

    @Dependency(\.defaultDatabase) var database
    let existingTripData: TripData? = try? database.read { db in
      try TripData.where { $0.tripID.eq(tripID) }.fetchOne(db)
    }
    
    var tripData = {
      guard let honestTripData = existingTripData else {
        DokoLogging.shared.postLoggingResponse(.database("postTripData: creating"))
        return TripData(tripID: tripID)
      }
      return honestTripData
    }()
    
    let timestamp = tripDataPacket.completedAt
    tripData.odometer.append(DokoDataPoint(timestamp: timestamp, double: odometer))
    if let batteryStateOfCharge = tripDataPacket.batteryStateOfCharge {
      tripData.stateOfCharge.append(DokoDataPoint(timestamp: timestamp, double: batteryStateOfCharge))
    }
    if let batteryEnergy = tripDataPacket.batteryEnergy {
      tripData.batteryEnergy.append(DokoDataPoint(timestamp: timestamp, double: batteryEnergy))
    }
    if let batteryEnergyToEmpty = tripDataPacket.batteryEnergyToEmpty {
      tripData.energyToEmpty.append(DokoDataPoint(timestamp: timestamp, double: batteryEnergyToEmpty))
    }
    if let batteryDistanceToEmpty = tripDataPacket.batteryDistanceToEmpty {
      tripData.distanceToEmpty.append(DokoDataPoint(timestamp: timestamp, double: batteryDistanceToEmpty))
    }
    if let batteryTemperature = tripDataPacket.batteryTemperature {
      tripData.batteryTemp.append(DokoDataPoint(timestamp: timestamp, double: batteryTemperature))
    }
    withErrorReporting {
      do {
        try database.write { db in
          try TripData.upsert { tripData }.execute(db)
        }
        DokoLogging.shared.postLoggingResponse(.database("postTripData: success"))
      } catch {
        DokoLogging.shared.postLoggingResponse(.database("postTripData: \(error)"))
        throw error
      }
    }
  }
}
