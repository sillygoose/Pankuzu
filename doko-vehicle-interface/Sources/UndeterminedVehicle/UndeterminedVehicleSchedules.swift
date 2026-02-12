import OSLog

import DokoTypes
import DokoLogging

extension UndeterminedVehicle {
  public func createStateScheduler(for state: VehicleState) async -> StateEngineDokoSchedule? {
    self.logger.info("\(timestamp()) UV.createStateScheduler(\(state.description))")
    switch state {
    case .reset:
      return UndeterminedVehicle.resetDokoCommandSchedule
    case .protocolCheck(let busProtocol):
      switch busProtocol {
      case .iso15765_11bit:
        return UndeterminedVehicle.detectStp33VehicleDokoCommandSchedule
      case .iso15765_29bit:
        return UndeterminedVehicle.detectStp34VehicleDokoCommandSchedule
      }
    case .vin:
      return UndeterminedVehicle.vinDokoCommandSchedule
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
  public static let detectStp33VehicleDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(1),
      packetType: .protocolCheck(.iso15765_11bit)
    )
  ]
  public static let detectStp34VehicleDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(1),
      packetType: .protocolCheck(.iso15765_29bit)
    )
  ]
  public static let vinDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(1),
      packetType: .vin
    )
  ]
}
