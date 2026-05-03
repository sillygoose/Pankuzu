import Foundation

import DokoSchema
import DokoVehicleManager
import DokoLocationManager

extension DatabaseSeedingModel {
  static private let f150Vin: String = "1FTVW3L76SWG00000"

  private func batteryPower(_ chargeStart: Date) -> [DokoDataPoint] {
    let batteryPower: [DokoDataPoint] = [
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(0 * 30 * 60), double: 0),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(1 * 30 * 60), double: 2),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(2 * 30 * 60), double: 10.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(3 * 30 * 60), double: 10.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(4 * 30 * 60), double: 10.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(5 * 30 * 60), double: 10.5),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(6 * 30 * 60), double: 10.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(7 * 30 * 60), double: 10.3),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(8 * 30 * 60), double: 10.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(9 * 30 * 60), double: 10.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(10 * 30 * 60), double: 10.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(11 * 30 * 60), double: 10.5),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(12 * 30 * 60), double: 10.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(13 * 30 * 60), double: 10.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(14 * 30 * 60), double: 10.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(15 * 30 * 60), double: 10.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(16 * 30 * 60), double: 10.3),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(17 * 30 * 60), double: 10.4),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(18 * 30 * 60), double: 8.8),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(19 * 30 * 60), double: 6.5),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(20 * 30 * 60), double: 3.5),
    ]
    return batteryPower
  }
  
  private func batteryEnergyToEmpty(_ chargeStart: Date) -> [DokoDataPoint] {
    let batteryEnergyToEmpty: [DokoDataPoint] = [
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(0 * 30 * 60), double: 20.0),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(1 * 30 * 60), double: 23.1),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(2 * 30 * 60), double: 26.0),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(3 * 30 * 60), double: 29.9),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(4 * 30 * 60), double: 33.2),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(5 * 30 * 60), double: 35.9),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(6 * 30 * 60), double: 39.0),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(7 * 30 * 60), double: 42.0),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(8 * 30 * 60), double: 45.0),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(9 * 30 * 60), double: 48.0),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(10 * 30 * 60), double: 51.0),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(11 * 30 * 60), double: 54.2),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(12 * 30 * 60), double: 57.1),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(13 * 30 * 60), double: 60.2),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(14 * 30 * 60), double: 63.2),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(15 * 30 * 60), double: 66.1),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(16 * 30 * 60), double: 68.9),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(17 * 30 * 60), double: 72.1),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(18 * 30 * 60), double: 75.2),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(19 * 30 * 60), double: 77.5),
      DokoDataPoint(timestamp: chargeStart.addingTimeInterval(20 * 30 * 60), double: 80.0),
    ]
    return batteryEnergyToEmpty
  }
}

extension DatabaseSeedingModel {
  public func seedAcCharge(chargeStart: Date) {
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
      timeEnd: chargeStart.addingTimeInterval(36000),
      duration: 36000,
      chargerType: .ac,
      odometer: 10000,
      energyToEmptyStart: 20,
      energyToEmptyEnd: 80,
      energy: 60,
      distanceToEmptyStart: 100,
      distanceToEmptyEnd: 400,
      range: 300,
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
      energyToEmpty: batteryEnergyToEmpty(chargeStart)
    )
    withErrorReporting {
      try database.write { db in
        try ChargeHistory.upsert { chargeHistory }.execute(db)
      }
    }
  }
}
