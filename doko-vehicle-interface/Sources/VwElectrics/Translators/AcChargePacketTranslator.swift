import OSLog

import DokoTypes
import ObdLinkCore

extension VwElectrics {
  func acChargeStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let stateOfCharge = responsePacket.batteryStateOfCharge
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeStarting, response: .error("arguments"))
      return DokoResponsePacket(type: .acChargeStarting, responses: dokoResponses)
    }
    batteryPower = nil
    batteryEnergy = nil
    lastEnergyUpdateTime = responsePacket.completedAt
    lastBatteryPower = nil
    dokoResponses[.nextState] = DokoCommandResponse(command: .acChargeStarting, response: .nextState(.acChargeInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: .acChargeStarting, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: .acChargeStarting, response: .odometer(odometer))
//    if let batteryEnergy {
//      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeStarting, response: .batteryEnergy(batteryEnergy))
//    }
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .acChargeStarting, response: .batteryStateOfCharge(stateOfCharge))
    if let batteryTemperature = responsePacket.batteryTemperature {
      dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .acChargeStarting, response: .batteryTemperature(batteryTemperature))
    }
    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: .acChargeStarting, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    if let batteryCurrentCapacity = responsePacket.batteryCurrentCapacity, let batteryOriginalCapacity = responsePacket.batteryOriginalCapacity, batteryOriginalCapacity > 0 {
      let batteryStateOfHealth = 100 * batteryCurrentCapacity / batteryOriginalCapacity
      dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .acChargeStarting, response: .batteryStateOfHealth(batteryStateOfHealth))
    }
    if let weather = responsePacket.weather {
      dokoResponses[.weather] = DokoCommandResponse(command: .acChargeStarting, response: .weather(weather))
    }
    return DokoResponsePacket(type: .acChargeStarting, responses: dokoResponses)
  }
  
  func acChargeInProgressResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let acChargerStatus = responsePacket.acChargerStatus
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeInProgress, response: .error("arguments"))
      return DokoResponsePacket(type: .acChargeInProgress, responses: dokoResponses)
    }
    let nextState: VehicleState = acChargerStatus ? .acChargeInProgress: .acChargeEnding
    dokoResponses[.nextState] = DokoCommandResponse(command: .acChargeInProgress, response: .nextState(nextState))
    return DokoResponsePacket(type: .acChargeInProgress, responses: dokoResponses)
  }

  func acChargeUpdateResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    if let voltage = responsePacket.batteryVoltage, let current = responsePacket.batteryCurrent {
      dokoResponses[.batteryVoltage] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryVoltage(voltage))
      dokoResponses[.batteryCurrent] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryCurrent(current))
    }
    if let batteryPower {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryPower(batteryPower))
    }
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryEnergy(batteryEnergy))
    }
    if let stateOfCharge = responsePacket.batteryStateOfCharge {
      dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryStateOfCharge(stateOfCharge))
    }
    if let batteryTemperature = responsePacket.batteryTemperature {
      dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryTemperature(batteryTemperature))
    }
    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    return DokoResponsePacket(type: .acChargeUpdate, responses: dokoResponses)
  }

  func acChargeEndingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let stateOfCharge = responsePacket.batteryStateOfCharge
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeEnding, response: .error("arguments"))
      return DokoResponsePacket(type: .acChargeEnding, responses: dokoResponses)
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .acChargeEnding, response: .nextState(.idle))
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeEnding, response: .batteryEnergy(batteryEnergy))
    }
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .acChargeEnding, response: .batteryStateOfCharge(stateOfCharge))
    if let batteryTemperature = responsePacket.batteryTemperature {
      dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .acChargeEnding, response: .batteryTemperature(batteryTemperature))
    }
    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: .acChargeEnding, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    if let batteryCurrentCapacity = responsePacket.batteryCurrentCapacity, let batteryOriginalCapacity = responsePacket.batteryOriginalCapacity, batteryOriginalCapacity > 0 {
      let batteryStateOfHealth = 100 * batteryCurrentCapacity / batteryOriginalCapacity
      dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .acChargeEnding, response: .batteryStateOfHealth(batteryStateOfHealth))
    }
    return DokoResponsePacket(type: .acChargeEnding, responses: dokoResponses)
  }

  func acChargeEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryVoltage = responsePacket.batteryVoltage,
      let batteryCurrent = responsePacket.batteryCurrent
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeEnergy, response: .error("arguments"))
      return DokoResponsePacket(type: .acChargeEnergy, responses: dokoResponses)
    }
    let power = batteryVoltage * batteryCurrent * 0.001
    batteryPower = power
    if let lastTime = lastEnergyUpdateTime, let lastPower = lastBatteryPower {
      let deltaHours = responsePacket.completedAt.timeIntervalSince(lastTime) / 3600.0
      batteryEnergy = (batteryEnergy ?? 0.0) + (lastPower + power) / 2.0 * deltaHours
    }
    lastEnergyUpdateTime = responsePacket.completedAt
    lastBatteryPower = power
    dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeEnergy, response: .batteryPower(power))
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeEnergy, response: .batteryEnergy(batteryEnergy))
    }
    return DokoResponsePacket(type: .acChargeEnergy, responses: dokoResponses)
  }

  func acChargeHistoryResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let stateOfCharge = responsePacket.batteryStateOfCharge
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeHistory, response: .error("arguments"))
      return DokoResponsePacket(type: .acChargeHistory, responses: dokoResponses)
    }
    if let batteryPower {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeHistory, response: .batteryPower(batteryPower))
    }
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeHistory, response: .batteryEnergy(batteryEnergy))
    }
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .acChargeHistory, response: .batteryStateOfCharge(stateOfCharge))
    if let batteryTemperature = responsePacket.batteryTemperature {
      dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .acChargeHistory, response: .batteryTemperature(batteryTemperature))
    }
    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: .acChargeHistory, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    return DokoResponsePacket(type: .acChargeHistory, responses: dokoResponses)
  }
}
