import OSLog

import DokoTypes
import ObdLinkCore

extension FordMachE {
  func dcChargeStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let stateOfHealth = responsePacket.stateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.dcChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeStarting, response: .error("agruments"))
      return DokoResponsePacket(type: .dcChargeStarting, responses: dokoResponses)
    }
    batteryPower = 0.0
    batteryEnergy = 0.0
    lastEnergyUpdateTime = responsePacket.completedAt
    lastBatteryPower = nil
    dokoResponses[.nextState] = DokoCommandResponse(command: .dcChargeStarting, response: .nextState(.dcChargeInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: .dcChargeStarting, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: .dcChargeStarting, response: .odometer(odometer))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeStarting, response: .batteryEnergy(batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .dcChargeStarting, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .dcChargeStarting, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .dcChargeStarting, response: .batteryStateOfHealth(stateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .couplerTemperature(couplerTemperature))
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
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeInProgress, response: .error("agruments"))
      return DokoResponsePacket(type: .dcChargeInProgress, responses: dokoResponses)
    }
    let nextState: VehicleState = dcChargerStatus ? .dcChargeInProgress: .dcChargeEnding
    dokoResponses[.nextState] = DokoCommandResponse(command: .dcChargeInProgress, response: .nextState(nextState))
    return DokoResponsePacket(type: .dcChargeInProgress, responses: dokoResponses)
  }
  
  func dcChargeUpdateResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    dokoResponses[.batteryPower] = DokoCommandResponse(command: .dcChargeUpdate, response: .batteryPower(batteryPower))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeUpdate, response: .batteryEnergy(batteryEnergy))
    if let energyToEmpty = responsePacket.energyToEmpty {
      dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .dcChargeUpdate, response: .energyToEmpty(energyToEmpty))
    }
    if let stateOfCharge = responsePacket.stateOfCharge {
      dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .dcChargeUpdate, response: .stateOfCharge(stateOfCharge))
    }
    if let batteryTemperature = responsePacket.batteryTemperature {
      dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .dcChargeUpdate, response: .batteryTemperature(batteryTemperature))
    }
    if let couplerTemperature = responsePacket.dcChargerCouplerTemperature {
      dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .dcChargeUpdate, response: .couplerTemperature(couplerTemperature))
    }
    return DokoResponsePacket(type: .dcChargeUpdate, responses: dokoResponses)
  }

  func dcChargeEndingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let stateOfHealth = responsePacket.stateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.dcChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeEnding, response: .error("agruments"))
      return DokoResponsePacket(type: .dcChargeEnding, responses: dokoResponses)
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .dcChargeEnding, response: .nextState(.idle))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeEnding, response: .batteryEnergy(batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .dcChargeEnding, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .dcChargeEnding, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .dcChargeEnding, response: .batteryStateOfHealth(stateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .dcChargeEnding, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .dcChargeEnding, response: .couplerTemperature(couplerTemperature))
    return DokoResponsePacket(type: .dcChargeEnding, responses: dokoResponses)
  }

  func dcChargeEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryVoltage = responsePacket.batteryVoltage,
      let batteryCurrent = responsePacket.batteryCurrent
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeEnergy, response: .error("agruments"))
      return DokoResponsePacket(type: .dcChargeEnergy, responses: dokoResponses)
    }
    batteryPower = batteryVoltage * batteryCurrent * 0.001
    if let lastTime = lastEnergyUpdateTime, let lastPower = lastBatteryPower {
      let deltaHours = responsePacket.completedAt.timeIntervalSince(lastTime) / 3600.0
      batteryEnergy += (lastPower + batteryPower) / 2.0 * deltaHours
    }
    lastEnergyUpdateTime = responsePacket.completedAt
    lastBatteryPower = batteryPower
    dokoResponses[.batteryPower] = DokoCommandResponse(command: .dcChargeEnergy, response: .batteryPower(batteryPower))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeEnergy, response: .batteryEnergy(batteryEnergy))
    return DokoResponsePacket(type: .dcChargeEnergy, responses: dokoResponses)
  }

  func dcChargeHistoryPacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.dcChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeHistory, response: .error("agruments"))
      return DokoResponsePacket(type: .dcChargeHistory, responses: dokoResponses)
    }
    dokoResponses[.batteryPower] = DokoCommandResponse(command: .dcChargeHistory, response: .batteryPower(batteryPower))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeHistory, response: .batteryEnergy(batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .dcChargeHistory, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .dcChargeHistory, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .dcChargeHistory, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .dcChargeHistory, response: .couplerTemperature(couplerTemperature))
    return DokoResponsePacket(type: .dcChargeHistory, responses: dokoResponses)
  }
}
