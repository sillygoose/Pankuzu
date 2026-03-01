import OSLog

import DokoTypes
import ObdLinkCore

extension VwElectrics {
  public func vehicleDokoResponsePacket(_ responsePacket: ObdResponsePacket) async -> DokoResponsePacket {
    switch responsePacket.type {
    case .vehicleCapabilities:
      return vehicleCapabilitiesResponsePacket(responsePacket)

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
      return dcChargeHistoryPacket(responsePacket)
    case .dcChargeEnding:
      return dcChargeEndingResponsePacket(responsePacket)

    default:
      return DokoResponsePacket(type: responsePacket.type, responses: [:])
    }
  }

  private func vehicleCapabilitiesResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
//    guard let odometer = responsePacket.odometer else {
//      return DokoResponsePacket(type: .vehicleCapabilities, responses: dokoResponses)
//    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .vehicleCapabilities, response: .nextState(.idle))
    if let odometer = responsePacket.odometer {
      dokoResponses[.odometer] = DokoCommandResponse(command: .vehicleCapabilities, response: .odometer(odometer))
    }
    if let obdOdometer = responsePacket.obdOdometer {
      dokoResponses[.obdOdometer] = DokoCommandResponse(command: .vehicleCapabilities, response: .obdOdometer(obdOdometer))
    }
    if let batteryVoltage = responsePacket.batteryVoltage, let batteryCurrent = responsePacket.batteryCurrent  {
      let batteryPower = batteryVoltage * batteryCurrent
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .vehicleCapabilities, response: .batteryPower(batteryPower))
    }
    if let batteryTemperature = responsePacket.batteryTemperature {
      dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .vehicleCapabilities, response: .batteryTemperature(batteryTemperature))
    }
    if let stateOfCharge = responsePacket.stateOfCharge {
      dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .vehicleCapabilities, response: .stateOfCharge(stateOfCharge))
    }
    return DokoResponsePacket(type: .vehicleCapabilities, responses: dokoResponses)
  }

  func idleResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let gearSelected = responsePacket.gearSelected,
      let acChargerStatus = responsePacket.acChargerStatus,
      let dcChargerStatus = responsePacket.dcChargerStatus
    else {
      return DokoResponsePacket(type: .idle, responses: dokoResponses)
    }
    var nextState: VehicleState {
      if gearSelected { return .tripStarting }
      if acChargerStatus { return .acChargeStarting }
      if dcChargerStatus { return .dcChargeStarting }
      return .idle
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .idle, response: .nextState(nextState))
    return DokoResponsePacket(type: .idle, responses: dokoResponses)
  }
  
//  func pluggedInResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
//    var dokoResponses: DokoResponseDictionary = [:]
//    guard
//      let pluggedIn = responsePacket.pluggedIn,
//      let acChargerStatus = responsePacket.acChargerStatus,
//      let dcChargerStatus = responsePacket.dcChargerStatus
//    else {
//      return DokoResponsePacket(type: .pluggedIn, responses: dokoResponses)
//    }
//    var nextState: VehicleState {
//      if !pluggedIn { return .idle }
//      if acChargerStatus { return .acChargeStarting }
//      if dcChargerStatus { return .dcChargeStarting }
//      return .pluggedIn
//    }
//    let chargeStatus = acChargerStatus || dcChargerStatus
//    dokoResponses[.nextState] = DokoCommandResponse(command: .pluggedIn, response: .nextState(nextState))
//    dokoResponses[.chargerStatus] = DokoCommandResponse(command: .pluggedIn, response: .chargerStatus(chargeStatus))
//    return DokoResponsePacket(type: .pluggedIn, responses: dokoResponses)
//  }
}
