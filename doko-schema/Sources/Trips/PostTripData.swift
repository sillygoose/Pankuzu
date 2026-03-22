import Foundation
import OSLog

import SQLiteData

import DokoTypes
import DokoSchemaTypes

@DokoEngineActor
extension Trip {
  public static func postTripDataRecord(
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
    var tripData = existingTripData ?? TripData(tripID: tripID)
    
    let timestamp = tripDataPacket.completedAt
    tripData.odometer.append(DokoDataPoint(timestamp: timestamp, double: odometer))
    if let stateOfCharge = tripDataPacket.batteryStateOfCharge {
      tripData.stateOfCharge.append(DokoDataPoint(timestamp: timestamp, double: stateOfCharge))
    }
    if let energyToEmpty = tripDataPacket.energyToEmpty {
      tripData.energyToEmpty.append(DokoDataPoint(timestamp: timestamp, double: energyToEmpty))
    }
    if let batteryEnergy = tripDataPacket.batteryEnergy {
      tripData.batteryEnergy.append(DokoDataPoint(timestamp: timestamp, double: batteryEnergy))
    }
    if let batteryTemp = tripDataPacket.batteryTemperature {
      tripData.batteryTemp.append(DokoDataPoint(timestamp: timestamp, double: batteryTemp))
    }
    withErrorReporting {
      try database.write { db in
        try TripData.upsert { tripData }.execute(db)
      }
    }
  }
}
