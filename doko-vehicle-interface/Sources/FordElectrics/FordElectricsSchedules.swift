import OSLog

import DokoTypes
import DokoLogging
import ObdLinkCore

extension FordElectrics {
  public func createStateScheduler(for state: VehicleState) async -> StateEngineDokoSchedule? {
    self.logger.info("\(timestamp()) FE.createStateScheduler(\(state.description))")
    switch state {
    case .vehicleCapabilities:
      return FordElectrics.vehicleCapabilitiesDokoCommandSchedule

    case .idle:
      return FordElectrics.idleDokoCommandSchedule

    case .tripStarting:
      return FordElectrics.tripStartingDokoCommandSchedule
    case .tripInProgress:
      return FordElectrics.tripInProgressDokoCommandSchedule
    case .tripEnding:
      return FordElectrics.tripEndingDokoCommandSchedule

    case .acChargeStarting:
      return FordElectrics.acChargeStartingDokoCommandSchedule
    case .acChargeInProgress:
      return FordElectrics.acChargeInProgressDokoCommandSchedule
    case .acChargeEnding:
      return FordElectrics.acChargeEndingDokoCommandSchedule

    case .dcChargeStarting:
      return FordElectrics.dcChargeStartingDokoCommandSchedule
    case .dcChargeInProgress:
      return FordElectrics.dcChargeInProgressDokoCommandSchedule
    case .dcChargeEnding:
      return FordElectrics.dcChargeEndingDokoCommandSchedule

    default:
      self.logger.error("\(timestamp()) FE.createStateScheduler: No scheduler for state '\(state.description)'")
      DokoLogging.shared.postLoggingResponse(.error("FE.createStateScheduler: No scheduler for state '\(state.description)'"))
      return nil
    }
  }
}

extension FordElectrics {
  private static let vehicleCapabilitiesDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(1),
      packetType: .vehicleCapabilities
    )
  ]

  private static let idleDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .firesThenDelays(2),
      packetType: .idle
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .firesThenDelays(3),
      packetType: .testerPresent
    )
  ]

  private static let tripStartingDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(2),
      packetType: .tripStarting
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(3),
      packetType: .testerPresent
    )
  ]
  private static let tripInProgressDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(2),
      packetType: .tripInProgress
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(2),
      packetType: .tripEnergy
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(10),
      packetType: .tripUpdate
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(30),
      packetType: .tripData
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(300),
      packetType: .tripWeather
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(3),
      packetType: .testerPresent
    )
  ]
  private static let tripEndingDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShot,
      packetType: .tripEnding
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(2),
      packetType: .testerPresent
    )
  ]
 
  private static let acChargeStartingDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(2),
      packetType: .acChargeStarting
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(2),
      packetType: .testerPresent
    )
  ]
  private static let acChargeInProgressDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(2),
      packetType: .acChargeInProgress
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(3),
      packetType: .acChargeEnergy
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(10),
      packetType: .acChargeUpdate
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(30),
      packetType: .acChargeHistory
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(3),
      packetType: .testerPresent
    )
  ]
  private static let acChargeEndingDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShot,
      packetType: .acChargeEnding
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(2),
      packetType: .testerPresent
    )
  ]

  private static let dcChargeStartingDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(2),
      packetType: .dcChargeStarting
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(2),
      packetType: .testerPresent
    )
  ]
  private static let dcChargeInProgressDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(2),
      packetType: .dcChargeInProgress
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(3),
      packetType: .dcChargeEnergy
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(10),
      packetType: .dcChargeUpdate
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .delaysThenFires(5),
      packetType: .dcChargeHistory
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(3),
      packetType: .testerPresent
    )
  ]
  private static let dcChargeEndingDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShot,
      packetType: .dcChargeEnding
    ),
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(2),
      packetType: .testerPresent
    )
  ]
}
