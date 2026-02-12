import Foundation
import OSLog

import SQLiteData

import DokoTypes
import DokoSchemaTypes

@DokoEngineActor
extension Trip {
  public static func postTripWeatherRecord(
    tripID: Trip.ID,
    tripWeatherPacket: DokoResponsePacket
  ) throws {
    guard
      let weather = tripWeatherPacket.weather
    else {
      throw TripError.tripWeatherArgumentError
    }

    @Dependency(\.defaultDatabase) var database
    let existingTripWeather: TripWeather? = try? database.read { db in
      try TripWeather.where { $0.tripID.eq(tripID) }.fetchOne(db)
    }
    var tripWeather = existingTripWeather ?? TripWeather(tripID: tripID)
    
    tripWeather.weather.append(DokoWeather(currentWeather: weather))
    withErrorReporting {
      try database.write { db in
        try TripWeather.upsert { tripWeather }.execute(db)
      }
    }
  }
}
