import Foundation

import DokoSchema
import DokoVehicleManager
import DokoLocationManager

extension DatabaseSeedingModel {
  static private let f150Vin: String = "1FTVW3L76SWG00000"

  private func batteryPower(_ chargeStart: Date) -> [DokoDataPoint] {
    let batteryPower: [DokoDataPoint] = [
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(0 * 60), double: 0),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(2 * 60), double: 72),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(4 * 60), double: 110.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(6 * 60), double: 150.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(8 * 60), double: 149.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(10 * 60), double: 148.5),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(12 * 60), double: 142.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(14 * 60), double: 136.3),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(16 * 60), double: 128.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(18 * 60), double: 123.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(20 * 60), double: 120.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(22 * 60), double: 118.5),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(24 * 60), double: 114.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(26 * 60), double: 101.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(28 * 60), double: 92.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(30 * 60), double: 53.4),
    ]
    return batteryPower
  }
  
  private func energyToEmpty(_ chargeStart: Date) -> [DokoDataPoint] {
    let energyToEmpty: [DokoDataPoint] = [
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(0 * 60), double: 20),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(2 * 60), double: 23),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(4 * 60), double: 32.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(6 * 60), double: 38.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(8 * 60), double: 41.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(10 * 60), double: 46.5),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(12 * 60), double: 51.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(14 * 60), double: 55.3),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(16 * 60), double: 59.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(18 * 60), double: 63.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(20 * 60), double: 67.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(22 * 60), double: 70.5),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(24 * 60), double: 72.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(26 * 60), double: 74.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(28 * 60), double: 76.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(30 * 60), double: 80.0),
    ]
    return energyToEmpty
  }
}

extension DatabaseSeedingModel {
  public func seedDcCharge(chargeStart: Date) {
    let vehicleID = DokoVehicleManager.shared.addVehicle(newVehicle: Vehicle(vin: DatabaseSeedingModel.f150Vin, name: "Example F-150"))
    let locationID = DokoLocationManager.shared.addLocation(latitude: 42.947846, longitude: -76.428322, elevation: 266.4)
    guard let vehicleID, let locationID else {
      return
    }

    let charge = Charge.Draft(
      deleted: nil,
      vehicleID: vehicleID,
      locationID: locationID,
      latitude: 42.947846,
      longitude: -76.428322,
      elevation: 271,
      timeStart: chargeStart,
      timeEnd: chargeStart.addingTimeInterval(1800),
      duration: 1800,
      chargerType: .dc,
      odometer: 10000,
      energyToEmptyStart: 20,
      energyToEmptyEnd: 80,
      energy: 60,
      stateOfChargeStart: 23,
      stateOfChargeEnd: 80,
      batteryStateOfHealth: 97.5,
      batteryTempStart: 23,
      batteryTempEnd: 52,
      couplerTempStart: 25,
      couplerTempEnd: 75,
      weatherTempStart: -3,
      weatherConditionsStart: "sun.snow",
    )

    @Dependency(\.defaultDatabase) var database
    let chargeID: Charge.ID? = withErrorReporting {
      try database.write { db in
        let id = try Charge.upsert { charge }.returning(\.id).fetchOne(db)
        return id!
      }
    }
    guard let chargeID else {
      return
    }

    let chargeHistory = ChargeHistory(
      chargeID: chargeID,
      batteryPower: batteryPower(chargeStart),
      energyToEmpty: energyToEmpty(chargeStart)
    )
    withErrorReporting {
      try database.write { db in
        try ChargeHistory.upsert { chargeHistory }.execute(db)
      }
    }
  }
}
