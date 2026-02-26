import OSLog

import DokoTypes
import DokoLogging
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
      .atz:                         "ATZ",
      .ate0:                        "ATE0",
      .ath0:                        "ATH0",
      .atcaf1:                      "ATCAF1",
      .ats0:                        "ATS0",
      .stcsegr1:                    "STCSEGR1",
      .atsp0:                       "ATSP0",
      .stprs:                       "STPRS",

      .extendedDiagnosticSession:   "1003",
      .vin:                         "0902",
    ]
    guard let obdLinkCommand = commandLookupDictionary[command] else {
      DokoLogging.shared.postLoggingResponse(.error("vehicleObdCommand: \(command.description) not found"))
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
          .atz, .ate0, .ath0, .atcaf1, .ats0, .stcsegr1, .atsp0
        ])

    case .vin:
      return ObdCommandPacket(
        type: .vin,
        commands: [
          .vin, .stprs, .extendedDiagnosticSession
        ])

    default:
      DokoLogging.shared.postLoggingResponse(.error("translateDokoCommandPacket: unexpected \(packetType.description) packet"))
      return nil
    }
  }
}

