import OSLog

import DokoTypes
import DokoLogging
import ObdLinkCore

extension VwElectrics {
  public func createStateScheduler(for state: VehicleState) async -> StateEngineDokoSchedule? {
    self.logger.info("\(timestamp()) VWE.createStateScheduler(\(state.description))")
    switch state {
    case .vehicleCapabilities:
      return VwElectrics.vehicleCapabilitiesDokoCommandSchedule
      
    case .idle:
      return VwElectrics.idleDokoCommandSchedule
      
    case .tripStarting:
      return VwElectrics.tripStartingDokoCommandSchedule
    case .tripInProgress:
      return VwElectrics.tripInProgressDokoCommandSchedule
    case .tripEnding:
      return VwElectrics.tripEndingDokoCommandSchedule
      
    case .acChargeStarting:
      return VwElectrics.acChargeStartingDokoCommandSchedule
    case .acChargeInProgress:
      return VwElectrics.acChargeInProgressDokoCommandSchedule
    case .acChargeEnding:
      return VwElectrics.acChargeEndingDokoCommandSchedule
      
    case .dcChargeStarting:
      return VwElectrics.dcChargeStartingDokoCommandSchedule
    case .dcChargeInProgress:
      return VwElectrics.dcChargeInProgressDokoCommandSchedule
    case .dcChargeEnding:
      return VwElectrics.dcChargeEndingDokoCommandSchedule
      
    default:
      self.logger.error("\(timestamp()) VWE.createStateScheduler: No scheduler for state '\(state.description)'")
      DokoLogging.shared.postLoggingResponse(.error("VWE.createStateScheduler: No scheduler for state '\(state.description)'"))
      return nil
    }
  }
}

extension VwElectrics {
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
      schedulerType: .oneShotWithDelay(1),
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
      schedulerType: .oneShotWithDelay(1),
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
