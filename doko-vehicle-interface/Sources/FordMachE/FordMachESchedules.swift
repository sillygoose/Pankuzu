import OSLog

import DokoTypes
import DokoLogging
import ObdLinkCore

extension FordMachE {
  public func createStateScheduler(for state: VehicleState) async -> StateEngineDokoSchedule? {
    self.logger.info("\(timestamp()) FME.createStateScheduler(\(state.description))")
    switch state {
    case .vehicleCustomization:
      return FordMachE.vehicleCustomizationDokoCommandSchedule

    case .idle:
      return FordMachE.idleDokoCommandSchedule

    case .tripStarting:
      return FordMachE.tripStartingDokoCommandSchedule
    case .tripInProgress:
      return FordMachE.tripInProgressDokoCommandSchedule
    case .tripEnding:
      return FordMachE.tripEndingDokoCommandSchedule

    case .acChargeStarting:
      return FordMachE.acChargeStartingDokoCommandSchedule
    case .acChargeInProgress:
      return FordMachE.acChargeInProgressDokoCommandSchedule
    case .acChargeEnding:
      return FordMachE.acChargeEndingDokoCommandSchedule

    case .dcChargeStarting:
      return FordMachE.dcChargeStartingDokoCommandSchedule
    case .dcChargeInProgress:
      return FordMachE.dcChargeInProgressDokoCommandSchedule
    case .dcChargeEnding:
      return FordMachE.dcChargeEndingDokoCommandSchedule

    default:
      self.logger.error("\(timestamp()) FME.createStateScheduler: No scheduler for state '\(state.description)'")
      DokoLogging.shared.postLoggingResponse(.error("FME.createStateScheduler: No scheduler for state '\(state.description)'"))
      return nil
    }
  }
}

extension FordMachE {
  private static let vehicleCustomizationDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(1),
      packetType: .vehicleCustomization
    )
  ]

  private static let idleDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .firesThenDelays(2),
      packetType: .idle
    ),
  ]

  private static let tripStartingDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(2),
      packetType: .tripStarting
    ),
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
      schedulerType: .firesThenDelays(300),
      packetType: .tripWeather
    ),
  ]
  private static let tripEndingDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShot,
      packetType: .tripEnding
    ),
  ]
 
  private static let acChargeStartingDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(2),
      packetType: .acChargeStarting
    ),
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
  ]
  private static let acChargeEndingDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShot,
      packetType: .acChargeEnding
    ),
  ]

  private static let dcChargeStartingDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShotWithDelay(2),
      packetType: .dcChargeStarting
    ),
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
  ]
  private static let dcChargeEndingDokoCommandSchedule: StateEngineDokoSchedule = [
    StateEngineDokoCommandPacket(
      schedulerType: .oneShot,
      packetType: .dcChargeEnding
    ),
  ]
}
