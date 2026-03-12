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
      return dcChargeHistoryPacket(responsePacket)
    case .dcChargeEnding:
      return dcChargeEndingResponsePacket(responsePacket)

    default:
      return DokoResponsePacket(type: responsePacket.type, responses: [:])
    }
  }

  private func vehicleCustomizationResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
//    guard let odometer = responsePacket.odometer else {
//      return DokoResponsePacket(type: .vehicleCustomization, responses: dokoResponses)
//    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .vehicleCustomization, response: .nextState(.idle))
    if let odometer = responsePacket.odometer {
      dokoResponses[.odometer] = DokoCommandResponse(command: .vehicleCustomization, response: .odometer(odometer))
    }
    if let obdOdometer = responsePacket.obdOdometer {
      dokoResponses[.obdOdometer] = DokoCommandResponse(command: .vehicleCustomization, response: .obdOdometer(obdOdometer))
    }
    if let batteryVoltage = responsePacket.batteryVoltage, let batteryCurrent = responsePacket.batteryCurrent  {
      let batteryPower = batteryVoltage * batteryCurrent
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .vehicleCustomization, response: .batteryPower(batteryPower))
    }
    if let batteryTemperature = responsePacket.batteryTemperature {
      dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .vehicleCustomization, response: .batteryTemperature(batteryTemperature))
    }
    if let stateOfCharge = responsePacket.stateOfCharge {
      dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .vehicleCustomization, response: .stateOfCharge(stateOfCharge))
    }
    return DokoResponsePacket(type: .vehicleCustomization, responses: dokoResponses)
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
}
