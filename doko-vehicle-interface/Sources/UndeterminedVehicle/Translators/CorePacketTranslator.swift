import OSLog

import DokoTypes
import ObdLinkCore

extension UndeterminedVehicle {
  public func vehicleDokoResponsePacket(_ responsePacket: ObdResponsePacket) async -> DokoResponsePacket {
    switch responsePacket.type {
    case .reset:
      return resetResponsePacket(responsePacket)
    case .vin:
      return vinResponsePacket(responsePacket)
    default:
      return DokoResponsePacket(type: responsePacket.type, responses: [:])
    }
  }
  
  private func resetResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let version = responsePacket.atz,
      let _ = responsePacket.ate,
      let _ = responsePacket.ath,
      let _ = responsePacket.ats,
      let _ = responsePacket.atcaf,
      let _ = responsePacket.stcsegr,
      let _ = responsePacket.atsp
    else {
      return DokoResponsePacket(type: .reset, responses: dokoResponses)
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .reset, response: .nextState(.vin))
    dokoResponses[.reset] = DokoCommandResponse(command: .reset, response: .reset(version))
    return DokoResponsePacket(type: .reset, responses: dokoResponses)
  }
  
  private func vinResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let protocolString = responsePacket.stprs,
      let vin = responsePacket.vin
    else {
      return DokoResponsePacket(type: .vin, responses: dokoResponses)
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .vin, response: .nextState(.vehicleCapabilities))
    dokoResponses[.vin] = DokoCommandResponse(command: .vin, response: .vin(vin))
    dokoResponses[.stprs] = DokoCommandResponse(command: .stprs, response: .stprs(protocolString))
    return DokoResponsePacket(type: .vin, responses: dokoResponses)
  }
}
