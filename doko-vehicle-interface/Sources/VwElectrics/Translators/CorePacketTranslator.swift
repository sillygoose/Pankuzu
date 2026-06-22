import OSLog

import DokoTypes
import ObdLinkCore

extension VwElectrics {
  public func vehicleDokoResponsePacket(_ responsePacket: ObdResponsePacket) async -> DokoResponsePacket {
    switch responsePacket.type {
    case .vehicleCustomization:
      return vehicleCustomizationResponsePacket(responsePacket)

    case .idle:
      return idleResponsePacket(responsePacket)

    case .tripStarting:
      return tripStartingResponsePacket(responsePacket)
    case .tripInProgress:
      return tripInProgressResponsePacket(responsePacket)
    case .tripUpdate:
      return await tripUpdateResponsePacket(responsePacket)
    case .tripEnergy:
      return tripEnergyResponsePacket(responsePacket)
    case .tripData:
      return tripDataResponsePacket(responsePacket)
    case .tripWeather:
      return tripWeatherResponsePacket(responsePacket)
    case .tripEnding:
      return await tripEndingResponsePacket(responsePacket)

    case .acChargeStarting:
      return acChargeStartingResponsePacket(responsePacket)
    case .acChargeInProgress:
      return acChargeInProgressResponsePacket(responsePacket)
    case .acChargeUpdate:
      return acChargeUpdateResponsePacket(responsePacket)
    case .acChargeEnergy:
      return acChargeEnergyResponsePacket(responsePacket)
    case .acChargeHistory:
      return acChargeHistoryResponsePacket(responsePacket)
    case .acChargeEnding:
      return acChargeEndingResponsePacket(responsePacket)

    case .dcChargeStarting:
      return dcChargeStartingResponsePacket(responsePacket)
    case .dcChargeInProgress:
      return dcChargeInProgressResponsePacket(responsePacket)
    case .dcChargeUpdate:
      return dcChargeUpdateResponsePacket(responsePacket)
    case .dcChargeEnergy:
      return dcChargeEnergyResponsePacket(responsePacket)
    case .dcChargeHistory:
      return dcChargeHistoryResponsePacket(responsePacket)
    case .dcChargeEnding:
      return dcChargeEndingResponsePacket(responsePacket)

    default:
      return DokoResponsePacket(type: responsePacket.type, responses: [:])
    }
  }

  private func vehicleCustomizationResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .vehicleCustomization
    let dokoCommand: DokoCommand = .vehicleCustomization
    var dokoResponses: DokoResponseDictionary = [:]
    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.idle))
//    if let batteryCurrentCapacity = responsePacket.batteryCurrentCapacity,
//       let batteryOriginalCapacity = responsePacket.batteryOriginalCapacity,
//       batteryOriginalCapacity > 0
//    {
//      let batteryStateOfHealth = 100 * batteryCurrentCapacity / batteryOriginalCapacity
//      dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .vehicleCustomization, response: .batteryStateOfHealth(batteryStateOfHealth))
//    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  func idleResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .idle
    let dokoCommand: DokoCommand = .idle
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let gearSelected = responsePacket.gearSelected,
      let acChargerStatus = responsePacket.acChargerStatus,
      let dcChargerStatus = responsePacket.dcChargerStatus
    else {
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    var nextState: VehicleState {
      if gearSelected { return .tripStarting }
      if acChargerStatus { return .acChargeStarting }
      if dcChargerStatus { return .dcChargeStarting }
      return .idle
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(nextState))
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }
}
