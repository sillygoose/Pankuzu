import OSLog

import DokoTypes
import ObdLinkCore
import VehicleInterface
import Vehicles

public actor UndeterminedVehicle: ConnectedVehicleInterface {
  let logger = Logger(subsystem: "com.unchan.doko", category: "UndeterminedVehicle")

  nonisolated public let vehicle: Vehicle?
  nonisolated public let name: String = "UndeterminedVehicle"

  public init() {
    self.vehicle = nil
  }

  public func vehicleObdCommand(_ command: ObdCommand) async -> String? {
    typealias CommandLookupDictionary = [ObdCommand: String]
    let commandLookupDictionary: CommandLookupDictionary = [
      .atz:                 "ATZ",
      .ate0:                "ATE0",
      .ath0:                "ATH0",
      .atcaf1:              "ATCAF1",
      .ats0:                "ATS0",
      .stcsegr1:            "STCSEGR1",
      .stp33:               "STP33",
      .stp34:               "STP34",
      
      .odometerAvailable:   "01A0",
      .vin:                 "0902",
    ]
    guard let obdLinkCommand = commandLookupDictionary[command] else {
      return nil
    }
    return obdLinkCommand
  }
  
  public func translateDokoCommandPacket(using packetType: DokoPacketType) async -> ObdCommandPacket? {
    switch packetType {
    case .reset:
      return ObdCommandPacket(
        type: .reset,
        commands: [
          .atz, .ate0, .ath0, .atcaf1, .ats0, .stcsegr1
        ])
    case .protocolCheck(let busProtocol):
      switch busProtocol {
      case .iso15765_11bit:
        return ObdCommandPacket(
          type: .protocolCheck(.iso15765_11bit),
          commands: [
            .stp33, .odometerAvailable
          ])
      case .iso15765_29bit:
        return ObdCommandPacket(
          type: .protocolCheck(.iso15765_29bit),
          commands: [
            .stp34, .odometerAvailable
          ])
      }
    case .vin:
      return ObdCommandPacket(
        type: .vin,
        commands: [
          .vin
        ])
      
    default:
      return nil
    }
  }
}

