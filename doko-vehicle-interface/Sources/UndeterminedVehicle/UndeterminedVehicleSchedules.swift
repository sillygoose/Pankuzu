import OSLog

import DokoTypes
import DokoLogging

extension UndeterminedVehicle {
  public func createStateScheduler(for state: VehicleState) async -> StateEngineDokoSchedule? {
    self.logger.info("\(timestamp()) UV.createStateScheduler(\(state.description))")
    switch state {
    case .reset:
      return UndeterminedVehicle.resetDokoCommandSchedule
    case .vin:
      return UndeterminedVehicle.VinDokoCommandSchedule
    default:
      DokoLogging.shared.postLoggingResponse(.error("UV.createStateScheduler: No scheduler for state '\(state.description)'"))
      return nil
    }
  }
}

extension UndeterminedVehicle {
  public static let resetDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShot,
      packetType: .reset
    )
  ]
  public static let VinDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(1),
      packetType: .vin
    )
  ]
}
