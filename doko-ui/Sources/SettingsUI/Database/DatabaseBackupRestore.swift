import Foundation
import SwiftUI
import OSLog
import UniformTypeIdentifiers

import DokoSchema
import DokoSharing

struct RestoreOptions {
  var includeTrips: Bool = true
  var includeCharges: Bool = true
  var includeSettings: Bool = false
}

struct BackupOptions {
  var includeTrips: Bool = true
  var includeCharges: Bool = true
  var includeSettings: Bool = false
  var useDateRange: Bool = false

  // startDate is always midnight of the selected day.
  private var _startDate: Date
  var startDate: Date {
    get { _startDate }
    set { _startDate = Calendar.current.startOfDay(for: newValue) }
  }

  // endDate is always midnight of the day after the selected day (exclusive upper bound).
  private var _endDate: Date
  var endDate: Date {
    get { _endDate }
    set {
      let cal = Calendar.current
      _endDate = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: newValue) ?? newValue)
    }
  }

  init(now: Date = Date()) {
    let cal = Calendar.current
    _startDate = cal.startOfDay(for: now)
    _endDate = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now) ?? now)
  }
}

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

  var appSettings: AppSettings? = nil
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

func backupDatabase(options: BackupOptions = BackupOptions()) throws -> DatabaseBackup {
  @Dependency(\.date.now) var now
  @Shared(.appSettings) var appSettings

  @FetchAll(
    Trip
      .where {
        if !options.includeTrips {
          $0.id.in([] as [Trip.ID])
        } else if options.useDateRange {
          $0.timeStart.gte(options.startDate) && $0.timeStart.lt(options.endDate)
        }
      }
      .order { $0.timeStart.desc() }
  ) var trips

  let tripIDs = Set(trips.map(\.id))
  @FetchAll(TripPosition.where { $0.tripID.in(tripIDs) } ) var tripPositions
  @FetchAll(TripElevation.where { $0.tripID.in(tripIDs) } ) var tripElevations
  @FetchAll(TripData.where { $0.tripID.in(tripIDs) } ) var tripData
  @FetchAll(TripWeather.where { $0.tripID.in(tripIDs) } ) var tripWeatherData

  @FetchAll(
    Charge
      .where {
        if !options.includeCharges {
          $0.id.in([] as [Charge.ID])
        } else if options.useDateRange {
          $0.timeStart.gte(options.startDate) && $0.timeStart.lt(options.endDate)
        }
      }
      .order { $0.timeStart.desc() }
  ) var charges

  let chargeIDs = Set(charges.map(\.id))
  @FetchAll(ChargeHistory.where { $0.chargeID.in(chargeIDs) } ) var chargeHistories

  let vehicleIDs = Set(trips.map(\.vehicleID)).union(charges.map(\.vehicleID))
  @FetchAll(Vehicle.where { $0.id.in(vehicleIDs) } ) var vehicles

  let locationIDs = Set(trips.flatMap { [$0.originID, $0.destinationID] }).union(charges.map(\.locationID))
  @FetchAll(Location.where { $0.id.in(locationIDs) } ) var locations

  return DatabaseBackup(
    backupDate: now,
    vehicles: vehicles,
    locations: locations,
    trips: trips,
    tripPositions: tripPositions,
    tripElevations: tripElevations,
    tripData: tripData,
    tripWeatherData: tripWeatherData,
    charges: charges,
    chargeHistories: chargeHistories,
    appSettings: options.includeSettings ? appSettings : nil
  )
}

func restoreDatabase(from databaseBackup: DatabaseBackup, options: RestoreOptions = RestoreOptions()) throws {
  @Dependency(\.defaultDatabase) var database
  @Shared(.appSettings) var appSettings

  @FetchAll var vehicles: [Vehicle]
  @FetchAll var locations: [Location]

  @FetchAll var trips: [Trip]
  @FetchAll var tripPositions: [TripPosition]
  @FetchAll var tripElevations: [TripElevation]
  @FetchAll var tripData: [TripData]
  @FetchAll var tripWeatherData: [TripWeather]

  @FetchAll var charges: [Charge]
  @FetchAll var chargeHistories: [ChargeHistory]

  let restoreVehiclesAndLocations = options.includeTrips || options.includeCharges

  try database.write { db in
    if restoreVehiclesAndLocations {
      for vehicle in databaseBackup.vehicles {
        if vehicles.contains(where: { $0.id == vehicle.id }) { continue }
        try Vehicle
          .insert { vehicle }
          .execute(db)
      }
    }

    if options.includeTrips {
      for trip in databaseBackup.trips {
        if trips.contains(where: { $0.id == trip.id }) { continue }
        try Trip
          .insert { trip }
          .execute(db)
      }

      for tripPosition in databaseBackup.tripPositions {
        if tripPositions.contains(where: { $0.id == tripPosition.id }) { continue }
        try TripPosition
          .insert { tripPosition }
          .execute(db)
      }

      for tripElevation in databaseBackup.tripElevations {
        if tripElevations.contains(where: { $0.id == tripElevation.id }) { continue }
        try TripElevation
          .insert { tripElevation }
          .execute(db)
      }

      for tripDatum in databaseBackup.tripData {
        if tripData.contains(where: { $0.id == tripDatum.id }) { continue }
        try TripData
          .insert { tripDatum }
          .execute(db)
      }

      for tripWeather in databaseBackup.tripWeatherData {
        if tripWeatherData.contains(where: { $0.id == tripWeather.id }) { continue }
        try TripWeather
          .insert { tripWeather }
          .execute(db)
      }
    }

    if options.includeCharges {
      for charge in databaseBackup.charges {
        if charges.contains(where: { $0.id == charge.id }) { continue }
        try Charge
          .insert { charge }
          .execute(db)
      }

      for chargeHistory in databaseBackup.chargeHistories {
        if chargeHistories.contains(where: { $0.id == chargeHistory.id }) { continue }
        try ChargeHistory
          .insert { chargeHistory }
          .execute(db)
      }
    }

    if restoreVehiclesAndLocations {
      let referencedLocationIDs = Set(
        (options.includeTrips ? databaseBackup.trips.flatMap { [$0.originID, $0.destinationID] } : []) +
        (options.includeCharges ? databaseBackup.charges.map(\.locationID) : [])
      )
      for location in databaseBackup.locations where referencedLocationIDs.contains(location.id) {
        if location.id == UUID(0) { continue }
        if locations.contains(where: { $0.id == location.id }) { continue }
        try Location
          .insert { location }
          .execute(db)
      }
    }
  }
  if options.includeSettings, let restoredSettings = databaseBackup.appSettings {
    $appSettings.withLock { $0 = restoredSettings }
  }
  logger.info("Database restoration complete")
}

private let logger = Logger(subsystem: "Doko", category: "DatabaseBackupRestore")
