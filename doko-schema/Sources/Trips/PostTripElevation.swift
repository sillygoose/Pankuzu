import Foundation
import OSLog

import SQLiteData

import DokoTypes
import DokoSchemaTypes

@DokoEngineActor
extension Trip {
  public static func postTripElevationRecord(
    tripID: Trip.ID,
    tripElevationPacket: DokoResponsePacket
  ) throws {
    guard
      let position = tripElevationPacket.position
    else {
      throw TripError.tripElevationrgumentError
    }
    
    let elevations: [VehicleElevation] = [VehicleElevation(position: position)]
    @Dependency(\.defaultDatabase) var database
    let existingTripElevations: TripElevation? = try? database.read { db in
      try TripElevation.where { $0.tripID.eq(tripID) }.fetchOne(db)
    }
    var tripElevations = existingTripElevations ?? TripElevation(tripID: tripID)

    tripElevations.elevations += elevations
    withErrorReporting {
      try database.write { db in
        try TripElevation.upsert { tripElevations }.execute(db)
      }
    }
  }
}
