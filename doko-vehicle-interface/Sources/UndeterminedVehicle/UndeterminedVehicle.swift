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
    let obdLinkCommand: String?
    switch command {
    case .atz:                        obdLinkCommand = "ATZ"
    case .ate(let enabled):           obdLinkCommand = "ATE\(enabled ? 1 : 0)"
    case .ath(let enabled):           obdLinkCommand = "ATH\(enabled ? 1 : 0)"
    case .atcaf(let enabled):         obdLinkCommand = "ATCAF\(enabled ? 1 : 0)"
    case .ats(let enabled):           obdLinkCommand = "ATS\(enabled ? 1 : 0)"
    case .stcsegr(let enabled):       obdLinkCommand = "STCSEGR\(enabled ? 1 : 0)"
    case .atsp(let proto):            obdLinkCommand = "ATSP\(proto)"
    case .stprs:                      obdLinkCommand = "STPRS"
    case .vin:                        obdLinkCommand = "0902"
    default:                          obdLinkCommand = nil
    }
    guard let obdLinkCommand else {
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
          .atz, .ate(false), .ats(false), .ath(false), .atcaf(true), .stcsegr(true), .atsp(0)
        ])

    case .vin:
      return ObdCommandPacket(
        type: .vin,
        commands: [
          .vin, .stprs
        ])

    default:
      DokoLogging.shared.postLoggingResponse(.error("translateDokoCommandPacket: unexpected \(packetType.description) packet"))
      return nil
    }
  }
}

