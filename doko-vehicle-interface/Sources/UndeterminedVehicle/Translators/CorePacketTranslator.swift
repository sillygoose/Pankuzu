import OSLog

import DokoTypes
import ObdLinkCore

extension UndeterminedVehicle {
  public func vehicleDokoResponsePacket(_ responsePacket: ObdResponsePacket) async -> DokoResponsePacket {
    switch responsePacket.type {
    case .reset:
      return resetResponsePacket(responsePacket)
    case .protocolCheck:
      return protocolCheckResponsePacket(responsePacket)
    case .vin:
      return checkVinResponsePacket(responsePacket)
    default:
      return DokoResponsePacket(type: responsePacket.type, responses: [:])
    }
  }
  
  private func resetResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard let version = responsePacket.atz, let _ = responsePacket.ate0, let _ = responsePacket.ath0,
          let _ = responsePacket.atcaf1, let _ = responsePacket.ats0, let _ = responsePacket.stcsegr1 else {
      return DokoResponsePacket(type: .reset, responses: dokoResponses)
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .reset, response: .nextState(.protocolCheck(.iso15765_11bit)))
    dokoResponses[.reset] = DokoCommandResponse(command: .reset, response: .reset(version))
    return DokoResponsePacket(type: .reset, responses: dokoResponses)
  }
  
  private func protocolCheckResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard case let .protocolCheck(busProtocol) = responsePacket.type else {
      return DokoResponsePacket(type: .protocolCheck(.iso15765_11bit), responses: dokoResponses)
    }
    switch busProtocol {
    case .iso15765_11bit:
      dokoResponses[.nextState] = DokoCommandResponse(command: .protocolCheck, response: .nextState(.protocolCheck(.iso15765_29bit)))
      guard let _ = responsePacket.stp33, let odometerAvailable = responsePacket.odometerAvailable else {
        return DokoResponsePacket(type: .protocolCheck(.iso15765_11bit), responses: dokoResponses)
      }
      dokoResponses[.nextState] = DokoCommandResponse(command: .protocolCheck, response: .nextState(.vin))
      dokoResponses[.odometerAvailable] = DokoCommandResponse(command: .protocolCheck, response: .odometerAvailable(odometerAvailable))
      return DokoResponsePacket(type: .protocolCheck(.iso15765_11bit), responses: dokoResponses)

    case .iso15765_29bit:
      dokoResponses[.nextState] = DokoCommandResponse(command: .protocolCheck, response: .nextState(.protocolCheck(.iso15765_11bit)))
      guard let _ = responsePacket.stp33, let odometerAvailable = responsePacket.odometerAvailable else {
        return DokoResponsePacket(type: .protocolCheck(.iso15765_29bit), responses: dokoResponses)
      }
      dokoResponses[.nextState] = DokoCommandResponse(command: .protocolCheck, response: .nextState(.vin))
      dokoResponses[.odometerAvailable] = DokoCommandResponse(command: .protocolCheck, response: .odometerAvailable(odometerAvailable))
      return DokoResponsePacket(type: .protocolCheck(.iso15765_29bit), responses: dokoResponses)
    }
  }

  private func checkVinResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard let vin = responsePacket.vin else {
      return DokoResponsePacket(type: .vin, responses: dokoResponses)
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .vin, response: .nextState(.idle))
    dokoResponses[.vin] = DokoCommandResponse(command: .vin, response: .vin(vin))
    return DokoResponsePacket(type: .vin, responses: dokoResponses)
  }
}
