import OSLog

import DokoTypes
import DokoLogging
import ObdLinkCore
import VehicleInterface
import Vehicles

private struct CommandGroup {
  let commands: [ObdCommand]
}

@resultBuilder
private enum ObdCommandsBuilder {
  static func buildExpression(_ e: ObdCommand) -> [ObdCommand] { [e] }
  static func buildExpression(_ e: CommandGroup) -> [ObdCommand] { e.commands }
  static func buildBlock(_ components: [ObdCommand]...) -> [ObdCommand] { components.flatMap { $0 } }
}

private func obdCommandPacket(_ type: DokoPacketType, @ObdCommandsBuilder _ commands: () -> [ObdCommand]) -> ObdCommandPacket {
  ObdCommandPacket(type: type, commands: commands())
}

public actor UndeterminedVehicle: ConnectedVehicleInterface {
  let logger = Logger(subsystem: "com.unchan.doko", category: "UndeterminedVehicle")

  nonisolated public let vehicle: Vehicle?
  nonisolated public let name: String = "UndeterminedVehicle"

  #if DEBUG
  private let savedLogObdPackets: Bool
  #endif

  public init() {
    self.vehicle = nil
    #if DEBUG
    @Shared(.logObdPackets) var logObdPackets
    savedLogObdPackets = logObdPackets
    $logObdPackets.withLock { $0 = true }
    #endif
  }

  deinit {
    #if DEBUG
    @Shared(.logObdPackets) var logObdPackets
    $logObdPackets.withLock { $0 = savedLogObdPackets }
    #endif
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
      DokoLogging.shared.postLoggingResponse(.error("UV.vehicleObdCommand: \(command.description) not found"))
      return nil
    }
    return obdLinkCommand
  }
  
  private let reset = CommandGroup(commands: [.atz, .ate(false), .ats(false), .ath(false), .atcaf(true), .stcsegr(true), .atsp(0)])
  private let protocolDetect = CommandGroup(commands: [.vin, .stprs])

  public func translateDokoCommandPacket(using packetType: DokoPacketType) async -> ObdCommandPacket? {
    switch packetType {
    case .reset:
      return obdCommandPacket(.reset) {
        reset;
      }
      
    case .vin:
      return obdCommandPacket(.vin) {
        protocolDetect;
      }
      
    default:
      DokoLogging.shared.postLoggingResponse(.error("UV.translateDokoCommandPacket: unexpected \(packetType.description) packet"))
      return nil
    }
  }
}
