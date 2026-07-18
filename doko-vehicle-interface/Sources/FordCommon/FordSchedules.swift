import OSLog

import DokoTypes
import DokoLogging

let vehicleCustomizationDokoCommandSchedule: StateEngineDokoSchedule = [
  StateEngineDokoCommandPacket(schedulerType: .oneShotWithDelay(1), packetType: .vehicleCustomization),
]

let idleDokoCommandSchedule: StateEngineDokoSchedule = [
  StateEngineDokoCommandPacket(schedulerType: .firesThenDelays(2), packetType: .idle),
]

let tripStartingDokoCommandSchedule: StateEngineDokoSchedule = [
  StateEngineDokoCommandPacket(schedulerType: .oneShotWithDelay(2), packetType: .tripStarting),
]

let tripInProgressDokoCommandSchedule: StateEngineDokoSchedule = [
  StateEngineDokoCommandPacket(schedulerType: .delaysThenFires(2),   packetType: .tripInProgress),
  StateEngineDokoCommandPacket(schedulerType: .delaysThenFires(2),   packetType: .tripEnergy),
  StateEngineDokoCommandPacket(schedulerType: .delaysThenFires(10),  packetType: .tripUpdate),
  StateEngineDokoCommandPacket(schedulerType: .delaysThenFires(10),  packetType: .tripData),
  StateEngineDokoCommandPacket(schedulerType: .firesThenDelays(300), packetType: .tripWeather),
]

let tripEndingDokoCommandSchedule: StateEngineDokoSchedule = [
  StateEngineDokoCommandPacket(schedulerType: .oneShot, packetType: .tripEnding),
]

let acChargeStartingDokoCommandSchedule: StateEngineDokoSchedule = [
  StateEngineDokoCommandPacket(schedulerType: .oneShotWithDelay(2), packetType: .acChargeStarting),
]

let acChargeInProgressDokoCommandSchedule: StateEngineDokoSchedule = [
  StateEngineDokoCommandPacket(schedulerType: .delaysThenFires(2),  packetType: .acChargeInProgress),
  StateEngineDokoCommandPacket(schedulerType: .delaysThenFires(3),  packetType: .acChargeEnergy),
  StateEngineDokoCommandPacket(schedulerType: .delaysThenFires(10), packetType: .acChargeUpdate),
  StateEngineDokoCommandPacket(schedulerType: .delaysThenFires(30), packetType: .acChargeHistory),
]

let acChargeEndingDokoCommandSchedule: StateEngineDokoSchedule = [
  StateEngineDokoCommandPacket(schedulerType: .oneShot, packetType: .acChargeEnding),
]

let dcChargeStartingDokoCommandSchedule: StateEngineDokoSchedule = [
  StateEngineDokoCommandPacket(schedulerType: .oneShotWithDelay(2), packetType: .dcChargeStarting),
]

let dcChargeInProgressDokoCommandSchedule: StateEngineDokoSchedule = [
  StateEngineDokoCommandPacket(schedulerType: .delaysThenFires(2),  packetType: .dcChargeInProgress),
  StateEngineDokoCommandPacket(schedulerType: .delaysThenFires(3),  packetType: .dcChargeEnergy),
  StateEngineDokoCommandPacket(schedulerType: .delaysThenFires(10), packetType: .dcChargeUpdate),
  StateEngineDokoCommandPacket(schedulerType: .delaysThenFires(5),  packetType: .dcChargeHistory),
]

let dcChargeEndingDokoCommandSchedule: StateEngineDokoSchedule = [
  StateEngineDokoCommandPacket(schedulerType: .oneShot, packetType: .dcChargeEnding),
]

extension FordTranslating {
  public func createStateScheduler(for state: VehicleState) async -> StateEngineDokoSchedule? {
    logger.info("\(timestamp()) \(self.logName).createStateScheduler(\(state.description))")
    switch state {
    case .vehicleCustomization: return vehicleCustomizationDokoCommandSchedule
    case .idle:                 return idleDokoCommandSchedule
    case .tripStarting:         return tripStartingDokoCommandSchedule
    case .tripInProgress:       return tripInProgressDokoCommandSchedule
    case .tripEnding:           return tripEndingDokoCommandSchedule
    case .acChargeStarting:     return acChargeStartingDokoCommandSchedule
    case .acChargeInProgress:   return acChargeInProgressDokoCommandSchedule
    case .acChargeEnding:       return acChargeEndingDokoCommandSchedule
    case .dcChargeStarting:     return dcChargeStartingDokoCommandSchedule
    case .dcChargeInProgress:   return dcChargeInProgressDokoCommandSchedule
    case .dcChargeEnding:       return dcChargeEndingDokoCommandSchedule
    default:
      logger.error("\(timestamp()) \(self.logName).createStateScheduler: No scheduler for state '\(state.description)'")
      DokoLogging.shared.postLoggingResponse(.error("\(self.logName).createStateScheduler: No scheduler for state '\(state.description)'"))
      return nil
    }
  }
}
