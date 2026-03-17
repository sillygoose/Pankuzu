import OSLog

import DokoTypes
import ObdLinkCore

extension VwElectrics {
  func dcChargeStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeStarting, response: .error("arguments"))
      return DokoResponsePacket(type: .dcChargeStarting, responses: dokoResponses)
    }
    batteryPower = nil
    batteryEnergy = nil
    lastEnergyUpdateTime = responsePacket.completedAt
    lastBatteryPower = nil
    dokoResponses[.nextState] = DokoCommandResponse(command: .dcChargeStarting, response: .nextState(.dcChargeInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: .dcChargeStarting, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: .dcChargeStarting, response: .odometer(odometer))
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeStarting, response: .batteryEnergy(batteryEnergy))
    }
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .dcChargeStarting, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .batteryTemperature(batteryTemperature))
    if let weather = responsePacket.weather {
      dokoResponses[.weather] = DokoCommandResponse(command: .dcChargeStarting, response: .weather(weather))
    }
    return DokoResponsePacket(type: .dcChargeStarting, responses: dokoResponses)
  }
  
  func dcChargeInProgressResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let dcChargerStatus = responsePacket.dcChargerStatus
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeInProgress, response: .error("arguments"))
      return DokoResponsePacket(type: .dcChargeInProgress, responses: dokoResponses)
    }
    let nextState: VehicleState = dcChargerStatus ? .dcChargeInProgress: .dcChargeEnding
    dokoResponses[.nextState] = DokoCommandResponse(command: .dcChargeInProgress, response: .nextState(nextState))
    return DokoResponsePacket(type: .dcChargeInProgress, responses: dokoResponses)
  }
  
  func dcChargeUpdateResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    if let batteryPower {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .dcChargeUpdate, response: .batteryPower(batteryPower))
    }
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeUpdate, response: .batteryEnergy(batteryEnergy))
    }
    if let stateOfCharge = responsePacket.stateOfCharge {
      dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .dcChargeUpdate, response: .stateOfCharge(stateOfCharge))
    }
    if let batteryTemperature = responsePacket.batteryTemperature {
      dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .dcChargeUpdate, response: .batteryTemperature(batteryTemperature))
    }
    return DokoResponsePacket(type: .dcChargeUpdate, responses: dokoResponses)
  }

  func dcChargeEndingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeEnding, response: .error("arguments"))
      return DokoResponsePacket(type: .dcChargeEnding, responses: dokoResponses)
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .dcChargeEnding, response: .nextState(.idle))
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeEnding, response: .batteryEnergy(batteryEnergy))
    }
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .dcChargeEnding, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .dcChargeEnding, response: .batteryTemperature(batteryTemperature))
    return DokoResponsePacket(type: .dcChargeEnding, responses: dokoResponses)
  }

  func dcChargeEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryVoltage = responsePacket.batteryVoltage,
      let batteryCurrent = responsePacket.batteryCurrent
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeEnergy, response: .error("arguments"))
      return DokoResponsePacket(type: .dcChargeEnergy, responses: dokoResponses)
    }
    let power = batteryVoltage * batteryCurrent * 0.001
    batteryPower = power
    if let lastTime = lastEnergyUpdateTime, let lastPower = lastBatteryPower {
      let deltaHours = responsePacket.completedAt.timeIntervalSince(lastTime) / 3600.0
      batteryEnergy = (batteryEnergy ?? 0.0) + (lastPower + power) / 2.0 * deltaHours
    }
    lastEnergyUpdateTime = responsePacket.completedAt
    lastBatteryPower = power
    dokoResponses[.batteryPower] = DokoCommandResponse(command: .dcChargeEnergy, response: .batteryPower(power))
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeEnergy, response: .batteryEnergy(batteryEnergy))
    }
    return DokoResponsePacket(type: .dcChargeEnergy, responses: dokoResponses)
  }

  func dcChargeHistoryPacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeHistory, response: .error("arguments"))
      return DokoResponsePacket(type: .dcChargeHistory, responses: dokoResponses)
    }
    if let batteryPower {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .dcChargeHistory, response: .batteryPower(batteryPower))
    }
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeHistory, response: .batteryEnergy(batteryEnergy))
    }
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .dcChargeHistory, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .dcChargeHistory, response: .batteryTemperature(batteryTemperature))
    return DokoResponsePacket(type: .dcChargeHistory, responses: dokoResponses)
  }
}
