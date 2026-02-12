//import Foundation
//import OSLog
//
//import SQLiteData
//
//import DokoTypes
//import DokoSchemaTypes
//
//extension Charge {
//  public static func postChargeWeatherRecord(
//    chargeID: Charge.ID,
//    chargeWeatherPacket: DokoResponsePacket
//  ) throws {
//    guard
//      let weather = chargeWeatherPacket.weather
//    else {
//      throw ChargeError.chargeWeatherArgumentError
//    }
//
//    @Dependency(\.defaultDatabase) var database
//    let existingChargeWeather: ChargeWeather? = try? database.read { db in
//      try ChargeWeather.where { $0.chargeID.eq(chargeID) }.fetchOne(db)
//    }
//    var chargeWeather = existingChargeWeather ?? ChargeWeather(chargeID: chargeID)
//
//    chargeWeather.weather.append(DokoWeather(currentWeather: weather))
//    withErrorReporting {
//      try database.write { db in
//        try ChargeWeather.upsert { chargeWeather }.execute(db)
//      }
//    }
//  }
//}
