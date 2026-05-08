import Foundation
import OSLog

import SQLiteData

import DokoTypes
import DokoLogging
import DokoSchemaTypes

@DokoEngineActor
extension Trip {
  public static func postTripPositionRecord(
    tripID: Trip.ID,
    tripPositionPacket: DokoResponsePacket
  ) throws {
    guard
      let position = tripPositionPacket.position
    else {
      throw TripError.tripPositionArgumentError
    }
    
    let positions: [VehiclePosition] = [VehiclePosition(position: position)]
    @Dependency(\.defaultDatabase) var database
    let existingTripPositions: TripPosition? = try? database.read { db in
      try TripPosition.where { $0.tripID.eq(tripID) }.fetchOne(db)
    }
    var tripPositions = existingTripPositions ?? TripPosition(tripID: tripID)

    tripPositions.path += positions
    withErrorReporting {
      try database.write { db in
        try TripPosition.upsert { tripPositions }.execute(db)
      }
    }
  }
}
