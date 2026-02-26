import Foundation
import OSLog

import SQLiteData

import Trips
import Charges
import Locations

private let logger = Logger(subsystem: "DokoSchema", category: "AppDatabase")

public func appDatabase() throws -> any DatabaseWriter {
  @Dependency(\.context) var context

  let database: any DatabaseWriter

  var configuration = Configuration()
  configuration.foreignKeysEnabled = true
  configuration.prepareDatabase { db in
    db.add(function: $handleDeletedLocations)

#if DEBUG
    db.trace(options: .profile) {
      if context == .preview {
        print($0.expandedDescription)
      } else {
        logger.debug("\($0.expandedDescription)")
      }
    }
#endif
  }

  switch context {
  case .live:
    let path = URL.documentsDirectory.appending(component: ".doko.sqlite").path()
    logger.info("open \(path)")
    database = try DatabasePool(path: path, configuration: configuration)
  case .preview, .test:
    database = try DatabaseQueue(configuration: configuration)
  }

  var migrator = DatabaseMigrator()
#if DEBUG
  migrator.eraseDatabaseOnSchemaChange = true
#endif
  migrator.registerMigration("Create tables") { db in
    try #sql(
      """
      CREATE TABLE "vehicle" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "name" TEXT
      ) STRICT
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TABLE "location" (
       "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
       "deleted" TEXT,
       "hidden" INTEGER,
       "latitude" REAL NOT NULL,
       "longitude" REAL NOT NULL,
       "elevation" REAL NOT NULL,
       "name" TEXT,
       "street" TEXT,
       "city" TEXT,
       "stateProv" TEXT,
       "region" TEXT
      ) STRICT
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TABLE "trip" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "deleted" TEXT,
        "vehicleID" TEXT NOT NULL,
        "originID" TEXT NOT NULL,
        "destinationID" TEXT NOT NULL,
        "latitudeStart" REAL NOT NULL,
        "longitudeStart" REAL NOT NULL,
        "elevationStart" REAL NOT NULL,
        "latitudeEnd" REAL NOT NULL,
        "longitudeEnd" REAL NOT NULL,
        "elevationEnd" REAL NOT NULL,
        "timeStart" TEXT NOT NULL,
        "timeEnd" TEXT NOT NULL,
        "duration" REAL NOT NULL,
        "odometerStart" REAL NOT NULL,
        "odometerEnd" REAL NOT NULL,
        "distance" REAL NOT NULL,
        "energyToEmptyStart" REAL,
        "energyToEmptyEnd" REAL,
        "energy" REAL,
        "distanceToEmptyStart" REAL,
        "distanceToEmptyEnd" REAL,
        "range" REAL,
        "stateOfChargeStart" REAL,
        "stateOfChargeEnd" REAL,
        "batteryStateOfHealth" REAL,
        "batteryTempStart" REAL,
        "batteryTempEnd" REAL,
        "weatherTempStart" REAL,
        "weatherTempEnd" REAL,
        "weatherTempMeanWeighted" REAL,
        "weatherConditionsStart" TEXT,
        "weatherConditionsEnd" TEXT,
        FOREIGN KEY("vehicleID") REFERENCES "vehicle"("id") ON DELETE CASCADE
      ) STRICT
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TABLE "tripPosition" (
        "tripID" TEXT NOT NULL PRIMARY KEY REFERENCES "trip"("id") ON DELETE CASCADE,
        "path" TEXT NOT NULL
      ) STRICT
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TABLE "tripElevation" (
        "tripID" TEXT NOT NULL PRIMARY KEY REFERENCES "trip"("id") ON DELETE CASCADE,
        "elevations" TEXT NOT NULL
      ) STRICT
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TABLE "tripData" (
        "tripID" TEXT NOT NULL PRIMARY KEY REFERENCES "trip"("id") ON DELETE CASCADE,
        "odometer" TEXT NOT NULL,
        "stateOfCharge" TEXT NOT NULL,
        "batteryEnergy" TEXT NOT NULL,
        "energyToEmpty" TEXT NOT NULL,
        "batteryTemp" TEXT NOT NULL
      ) STRICT
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TABLE "tripWeather" (
        "tripID" TEXT NOT NULL PRIMARY KEY REFERENCES "trip"("id") ON DELETE CASCADE,
        "weather" TEXT NOT NULL
      ) STRICT
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TABLE "charge" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "deleted" TEXT,
        "vehicleID" TEXT NOT NULL,
        "locationID" TEXT NOT NULL,
        "latitude" REAL NOT NULL,
        "longitude" REAL NOT NULL,
        "elevation" REAL NOT NULL,
        "timeStart" TEXT NOT NULL,
        "timeEnd" TEXT NOT NULL,
        "duration" REAL NOT NULL,
        "chargerType" INTEGER NOT NULL,
        "odometer" REAL NOT NULL,
        "energyToEmptyStart" REAL,
        "energyToEmptyEnd" REAL,
        "energy" REAL,
        "distanceToEmptyStart" REAL,
        "distanceToEmptyEnd" REAL,
        "range" REAL,
        "stateOfChargeStart" REAL,
        "stateOfChargeEnd" REAL,
        "batteryStateOfHealth" REAL,
        "batteryTempStart" REAL,
        "batteryTempEnd" REAL,
        "couplerTempStart" REAL,
        "couplerTempEnd" REAL,
        "weatherTempStart" REAL,
        "weatherTempEnd" REAL,
        "weatherTempMeanWeighted" REAL,
        "weatherConditionsStart" TEXT,
        "weatherConditionsEnd" TEXT,
        FOREIGN KEY("vehicleID") REFERENCES "vehicle"("id") ON DELETE CASCADE
      ) STRICT
      """
    )
    .execute(db)
    
    try #sql(
      """
      CREATE TABLE "chargeHistory" (
        "chargeID" TEXT NOT NULL PRIMARY KEY REFERENCES "charge"("id") ON DELETE CASCADE,
        "batteryPower" TEXT NOT NULL,
        "batteryEnergy" TEXT NOT NULL,
        "stateOfCharge" TEXT NOT NULL,
        "energyToEmpty" TEXT NOT NULL,
        "batteryTemp" TEXT NOT NULL,
        "couplerTemp" TEXT NOT NULL
      ) STRICT
      """
    )
    .execute(db)
  }
  try migrator.migrate(database)
  
  // Default location placefolder
  try database.write { db in
    try Location.upsert { Location.defaultLocation }.execute(db)
  }

  try database.write { db in
    try Location.createTemporaryTrigger(
      after: .delete { old in
        #sql("SELECT \($handleDeletedLocations())")
      }
    )
    .execute(db)

    try Trip.createTemporaryTrigger(
      "soft_delete_origin_location_after_trip_soft_delete",
      after: .update(of: \.deleted) { old, new in
        Location
          .where { $0.id.eq(new.originID) && $0.deleted.is(nil) }
          .update { $0.deleted = new.deleted }
      } when: { old, new in
        old.deleted.is(nil) && new.deleted.isNot(nil)
        && !(
          Trip.where { ($0.originID.eq(new.originID) || $0.destinationID.eq(new.originID)) && $0.deleted.is(nil) }.exists() ||
          Charge.where { $0.locationID.eq(new.originID) && $0.deleted.is(nil) }.exists()
        )
      }
    )
    .execute(db)

    try Trip.createTemporaryTrigger(
      "soft_delete_destination_location_after_trip_soft_delete",
      after: .update(of: \.deleted) { old, new in
        Location
          .where { $0.id.eq(new.destinationID) && $0.deleted.is(nil) }
          .update { $0.deleted = new.deleted }
      } when: { old, new in
        old.deleted.is(nil) && new.deleted.isNot(nil)
        && !(
          Trip.where { ($0.originID.eq(new.destinationID) || $0.destinationID.eq(new.destinationID)) && $0.deleted.is(nil) }.exists() ||
          Charge.where { $0.locationID.eq(new.destinationID) && $0.deleted.is(nil) }.exists()
        )
      }
    )
    .execute(db)

    try Charge.createTemporaryTrigger(
      "soft_delete_location_after_charge_soft_delete",
      after: .update(of: \.deleted) { old, new in
        Location
          .where { $0.id.eq(new.locationID) && $0.deleted.is(nil) }
          .update { $0.deleted = new.deleted }
      } when: { old, new in
        old.deleted.is(nil) && new.deleted.isNot(nil)
        && !(
          Trip.where { ($0.originID.eq(new.locationID) || $0.destinationID.eq(new.locationID)) && $0.deleted.is(nil) }.exists() ||
          Charge.where { $0.locationID.eq(new.locationID) && $0.deleted.is(nil) }.exists()
        )
      }
    )
    .execute(db)

    try Trip.createTemporaryTrigger(
      "undelete_location_on_trip_insert",
      after: .insert { new in
        Location
          .where { $0.id.eq(new.originID) && $0.deleted.isNot(nil) }
          .update { $0.deleted = nil }
        Location
          .where { $0.id.eq(new.destinationID) && $0.deleted.isNot(nil) }
          .update { $0.deleted = nil }
      }
    )
    .execute(db)

    try Charge.createTemporaryTrigger(
      "undelete_location_on_charge_insert",
      after: .insert { new in
        Location
          .where { $0.id.eq(new.locationID) && $0.deleted.isNot(nil) }
          .update { $0.deleted = nil }
      }
    )
    .execute(db)

    try Trip.createTemporaryTrigger(
      "undelete_location_on_trip_restore",
      after: .update(of: \.deleted) { _, new in
        Location
          .where { $0.id.eq(new.originID) && $0.deleted.isNot(nil) }
          .update { $0.deleted = nil }
        Location
          .where { $0.id.eq(new.destinationID) && $0.deleted.isNot(nil) }
          .update { $0.deleted = nil }
      } when: { old, new in
        old.deleted.isNot(nil) && new.deleted.is(nil)
      }
    )
    .execute(db)

    try Charge.createTemporaryTrigger(
      "undelete_location_on_charge_restore",
      after: .update(of: \.deleted) { _, new in
        Location
          .where { $0.id.eq(new.locationID) && $0.deleted.isNot(nil) }
          .update { $0.deleted = nil }
      } when: { old, new in
        old.deleted.isNot(nil) && new.deleted.is(nil)
      }
    )
    .execute(db)

    try Trip.createTemporaryTrigger(
      "hard_delete_origin_location_after_trip_delete",
      after: .delete { old in
        Location
          .where { $0.id.eq(old.originID) }
          .delete()
      } when: { old in
        !(
          Trip.where { $0.originID.eq(old.originID) || $0.destinationID.eq(old.originID) }.exists() ||
          Charge.where { $0.locationID.eq(old.originID) }.exists()
        )
      }
    )
    .execute(db)

    try Trip.createTemporaryTrigger(
      "hard_delete_destination_location_after_trip_delete",
      after: .delete { old in
        Location
          .where { $0.id.eq(old.destinationID) }
          .delete()
      }
      when: { old in
        !(
          Trip.where { $0.originID.eq(old.destinationID) || $0.destinationID.eq(old.destinationID) }.exists() ||
          Charge.where { $0.locationID.eq(old.destinationID) }.exists()
        )
      }
    )
    .execute(db)

    try Charge.createTemporaryTrigger(
      "hard_delete_location_after_charge_delete",
      after: .delete { old in
        Location
          .where { $0.id.eq(old.locationID) }
          .delete()
      }
      when: { old in
        !(
          Trip.where { $0.originID.eq(old.locationID) || $0.destinationID.eq(old.locationID) }.exists() ||
          Charge.where { $0.locationID.eq(old.locationID) }.exists()
        )
      }
    )
    .execute(db)
  }

  return database
}

@DatabaseFunction
private func handleDeletedLocations() {
  Task {
    @Dependency(\.defaultDatabase) var database
    try await database.write { db in
      let isLocationsEmpty = try Location.count().fetchOne(db) == 0
      if isLocationsEmpty {
        try Location
          .upsert { Location.defaultLocation }
          .execute(db)
      }
    }
  }
}

extension DependencyValues {
  public mutating func bootstrapDatabase() throws {
    defaultDatabase = try appDatabase()
  }
}
