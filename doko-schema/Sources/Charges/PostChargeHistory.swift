import Foundation
import OSLog

import SQLiteData

import DokoTypes
import DokoSchemaTypes

extension Charge {
  public static func postChargeHistoryRecord(
    chargeID: Charge.ID,
    chargeHistoryPacket: DokoResponsePacket
  ) throws {
    let timestamp = chargeHistoryPacket.completedAt
    @Dependency(\.defaultDatabase) var database
    let existingChargeHistories: ChargeHistory? = try? database.read { db in
      try ChargeHistory.where { $0.chargeID.eq(chargeID) }.fetchOne(db)
    }
    var chargeHistories = existingChargeHistories ?? ChargeHistory(chargeID: chargeID)

    if let batteryPower = chargeHistoryPacket.batteryPower {
      chargeHistories.batteryPower.append(DokoDataPoint(timestamp: timestamp, double: batteryPower))
    }
    if let batteryStateOfCharge = chargeHistoryPacket.batteryStateOfCharge {
      chargeHistories.stateOfCharge.append(DokoDataPoint(timestamp: timestamp, double: batteryStateOfCharge))
    }
    if let batteryEnergy = chargeHistoryPacket.batteryEnergy {
      chargeHistories.batteryEnergy.append(DokoDataPoint(timestamp: timestamp, double: batteryEnergy))
    }
    if let batteryEnergyToEmpty = chargeHistoryPacket.batteryEnergyToEmpty {
      chargeHistories.energyToEmpty.append(DokoDataPoint(timestamp: timestamp, double: batteryEnergyToEmpty))
    }
    if let batteryTemperature = chargeHistoryPacket.batteryTemperature {
      chargeHistories.batteryTemp.append(DokoDataPoint(timestamp: timestamp, double: batteryTemperature))
    }
    if let couplerTemperature = chargeHistoryPacket.couplerTemperature {
      chargeHistories.couplerTemp.append(DokoDataPoint(timestamp: timestamp, double: couplerTemperature))
    }
    if let batteryDistanceToEmpty = chargeHistoryPacket.batteryDistanceToEmpty {
      if chargeHistories.distanceToEmpty == nil { chargeHistories.distanceToEmpty = [] }
      chargeHistories.distanceToEmpty!.append(DokoDataPoint(timestamp: timestamp, double: batteryDistanceToEmpty))
    }
    withErrorReporting {
      try database.write { db in
        try ChargeHistory.upsert { chargeHistories }.execute(db)
      }
    }
  }
}
