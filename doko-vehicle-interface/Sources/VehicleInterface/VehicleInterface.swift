import Foundation

import DokoTypes
import ObdLinkCore
import Vehicles

public protocol ConnectedVehicleInterface: Sendable {
  nonisolated var vehicle: Vehicle? { get }
  nonisolated var name: String { get }

  func createStateScheduler(for state: VehicleState) async -> StateEngineDokoSchedule?

  func translateDokoCommandPacket(using packetType: DokoPacketType) async -> ObdCommandPacket?

  func vehicleObdCommand(_ command: ObdCommand) async -> String?
  func vehicleDokoResponsePacket(_ responsePacket: ObdResponsePacket) async -> DokoResponsePacket
  func vehicleObdCommandResponse(_ command: ObdCommand, _ response: String, rawCommand: String) async -> ObdCommandResponse
}

