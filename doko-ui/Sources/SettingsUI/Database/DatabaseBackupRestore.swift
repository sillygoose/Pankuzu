import Foundation
import SwiftUI
import OSLog
import UniformTypeIdentifiers

import DokoSchema

struct DatabaseBackup: Codable {
  var backupDate: Date = Date()
  var vehicles: [Vehicle] = []
  var locations: [Location] = []
  
  var trips: [Trip] = []
  var tripPositions: [TripPosition] = []
  var tripElevations: [TripElevation] = []
  var tripData: [TripData] = []
  var tripWeatherData: [TripWeather] = []

  var charges: [Charge] = []
  var chargeHistories: [ChargeHistory] = []
}

struct JSONDocument: FileDocument {
  static var readableContentTypes: [UTType] { [.json] }
  static var writableContentTypes: [UTType] { [.json] }
  
  var backupModel: DatabaseBackup
  
  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    self.backupModel = try decoder.decode(DatabaseBackup.self, from: data)
  }
  
  init(initialModel: DatabaseBackup) {
    self.backupModel = initialModel
  }
  
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(self.backupModel)
    return FileWrapper(regularFileWithContents: data)
  }
}

func backupDatabase() throws -> DatabaseBackup {
  @FetchAll var vehicles: [Vehicle]
  @FetchAll var locations: [Location]
  
  @FetchAll var trips: [Trip]
  @FetchAll var tripPositions: [TripPosition]
  @FetchAll var tripElevations: [TripElevation]
  @FetchAll var tripData: [TripData]
  @FetchAll var tripWeatherData: [TripWeather]

  @FetchAll var charges: [Charge]
  @FetchAll var chargeHistories: [ChargeHistory]

  @Dependency(\.date.now) var now

  let backup = DatabaseBackup(
    backupDate: now,
    vehicles: vehicles,
    locations: locations,
    trips: trips,
    tripPositions: tripPositions,
    tripElevations: tripElevations,
    tripData: tripData,
    tripWeatherData: tripWeatherData,
    charges: charges,
    chargeHistories: chargeHistories
  )
  return backup
}

func restoreDatabase(from databaseBackup: DatabaseBackup) throws {
  @Dependency(\.defaultDatabase) var database
  
  @FetchAll var vehicles: [Vehicle]
  @FetchAll var locations: [Location]
  
  @FetchAll var trips: [Trip]
  @FetchAll var tripPositions: [TripPosition]
  @FetchAll var tripElevations: [TripElevation]
  @FetchAll var tripData: [TripData]
  @FetchAll var tripWeatherData: [TripWeather]

  @FetchAll var charges: [Charge]
  @FetchAll var chargeHistories: [ChargeHistory]

  try database.write { db in
    for vehicle in databaseBackup.vehicles {
      if let _ = vehicles.first(where: { $0.id == vehicle.id }) { continue }
      try Vehicle
        .insert { vehicle }
        .execute(db)
    }

    for location in databaseBackup.locations {
      if let _ = locations.first(where: { $0.id == location.id }) { continue }
      try Location
        .insert { location }
        .execute(db)
    }

    for trip in databaseBackup.trips {
      if let _ = trips.first(where: { $0.id == trip.id }) { continue }
      try Trip
        .insert { trip }
        .execute(db)
    }

    for tripPosition in databaseBackup.tripPositions {
      if let _ = tripPositions.first(where: { $0.id == tripPosition.id }) { continue }
      try TripPosition
        .insert { tripPosition }
        .execute(db)
    }

    for tripElevation in databaseBackup.tripElevations {
      if let _ = tripElevations.first(where: { $0.id == tripElevation.id }) { continue }
      try TripElevation
        .insert { tripElevation }
        .execute(db)
    }

    for tripDatum in databaseBackup.tripData {
      if let _ = tripData.first(where: { $0.id == tripDatum.id }) { continue }
      try TripData
        .insert { tripDatum }
        .execute(db)
    }

    for tripWeather in databaseBackup.tripWeatherData {
      if let _ = tripWeatherData.first(where: { $0.id == tripWeather.id }) { continue }
      try TripWeather
        .insert { tripWeather }
        .execute(db)
    }

    for charge in databaseBackup.charges {
      if let _ = charges.first(where: { $0.id == charge.id }) { continue }
      try Charge
        .insert { charge }
        .execute(db)
    }

    for chargeHistory in databaseBackup.chargeHistories {
      if let _ = chargeHistories.first(where: { $0.id == chargeHistory.id }) { continue }
      try ChargeHistory
        .insert { chargeHistory }
        .execute(db)
    }
  }
  logger.info("Database restoration complete")
}

private let logger = Logger(subsystem: "Doko", category: "DatabaseBackupRestore")
