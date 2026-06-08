import OSLog

import DokoTypes
import ObdLinkCore

extension FordElectrics {
  func acChargeStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.batteryEnergyToEmpty,
      let stateOfCharge = responsePacket.batteryStateOfCharge,
      let stateOfHealth = responsePacket.batteryStateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.acChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeStarting, response: .error("arguments"))
      return DokoResponsePacket(type: .acChargeStarting, responses: dokoResponses)
    }
    
    batteryPower = nil
    batteryEnergy = nil
    chargerInputPower = nil
    chargerInputEnergy = nil
    chargerOutputPower = nil
    chargerOutputEnergy = nil
    lastBatteryPower = nil
    lastChargerInputPower = nil
    lastChargerOutputPower = nil
    lastEnergyUpdateTime = responsePacket.completedAt

    dokoResponses[.nextState] = DokoCommandResponse(command: .acChargeStarting, response: .nextState(.acChargeInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: .acChargeStarting, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: .acChargeStarting, response: .odometer(odometer))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: .acChargeStarting, response: .batteryEnergyToEmpty(energyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .acChargeStarting, response: .batteryStateOfCharge(stateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .acChargeStarting, response: .batteryStateOfHealth(stateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .acChargeStarting, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .acChargeStarting, response: .couplerTemperature(couplerTemperature))
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
    if let batteryVoltage = responsePacket.batteryVoltage, let batteryCurrent = responsePacket.batteryCurrent {
      dokoResponses[.batteryVoltage] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryVoltage(batteryVoltage))
      dokoResponses[.batteryCurrent] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryCurrent(batteryCurrent))
    }
    if let batteryPower {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryPower(batteryPower))
    }
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryEnergy(batteryEnergy))
    }

    //###
    if let chargerInputVoltage = responsePacket.chargerInputVoltage, let chargerInputCurrent = responsePacket.chargerInputCurrent {
      dokoResponses[.chargerInputVoltage] = DokoCommandResponse(command: .acChargeUpdate, response: .chargerInputVoltage(chargerInputVoltage))
      dokoResponses[.chargerInputCurrent] = DokoCommandResponse(command: .acChargeUpdate, response: .chargerInputCurrent(chargerInputCurrent))
    }
    if let chargerInputPower {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryPower(chargerInputPower))
    }
    if let chargerInputEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryEnergy(chargerInputEnergy))
    }
    //###

    //###
    if let chargerOutputVoltage = responsePacket.chargerInputVoltage, let chargerOutputCurrent = responsePacket.chargerOutputCurrent {
      dokoResponses[.chargerOutputVoltage] = DokoCommandResponse(command: .acChargeUpdate, response: .chargerOutputVoltage(chargerOutputVoltage))
      dokoResponses[.chargerOutputCurrent] = DokoCommandResponse(command: .acChargeUpdate, response: .chargerOutputCurrent(chargerOutputCurrent))
    }
    if let chargerInputPower {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryPower(chargerInputPower))
    }
    if let chargerInputEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryEnergy(chargerInputEnergy))
    }
    //###

    if let stateOfCharge = responsePacket.batteryStateOfCharge {
      dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryStateOfCharge(stateOfCharge))
    }
    if let batteryTemperature = responsePacket.batteryTemperature {
      dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryTemperature(batteryTemperature))
    }
    if let couplerTemperature = responsePacket.acChargerCouplerTemperature {
      dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .acChargeUpdate, response: .couplerTemperature(couplerTemperature))
    }
    return DokoResponsePacket(type: .acChargeUpdate, responses: dokoResponses)
  }

  func acChargeEndingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let energyToEmpty = responsePacket.batteryEnergyToEmpty,
      let stateOfCharge = responsePacket.batteryStateOfCharge,
      let stateOfHealth = responsePacket.batteryStateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.acChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeEnding, response: .error("arguments"))
      return DokoResponsePacket(type: .acChargeEnding, responses: dokoResponses)
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .acChargeEnding, response: .nextState(.idle))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: .acChargeStarting, response: .batteryEnergyToEmpty(energyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .acChargeEnding, response: .batteryStateOfCharge(stateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .acChargeEnding, response: .batteryStateOfHealth(stateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .acChargeEnding, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .acChargeEnding, response: .couplerTemperature(couplerTemperature))
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeEnding, response: .batteryEnergy(batteryEnergy))
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
    let currentBatteryPower = batteryVoltage * batteryCurrent * 0.001
    batteryPower = currentBatteryPower
    if let lastTime = lastEnergyUpdateTime, let previousBattryPower = lastBatteryPower {
      let deltaHours = responsePacket.completedAt.timeIntervalSince(lastTime) / 3600.0
      batteryEnergy = (batteryEnergy ?? 0.0) + (previousBattryPower + currentBatteryPower) / 2.0 * deltaHours
    }
    lastBatteryPower = currentBatteryPower
    //### review this
    
    lastEnergyUpdateTime = responsePacket.completedAt

    //### review this
    if let batteryPower {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeEnergy, response: .batteryPower(batteryPower))
    }
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeEnergy, response: .batteryEnergy(batteryEnergy))
    }
    //### review this

    //### review this
    if let chargerInputPower {
      dokoResponses[.chargerInputPower] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerInputPower(chargerInputPower))
    }
    if let chargerInputEnergy {
      dokoResponses[.chargerInputEnergy] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerInputEnergy(chargerInputEnergy))
    }
    
    if let chargerOutputPower {
      dokoResponses[.chargerOutputPower] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerOutputPower(chargerOutputPower))
    }
    if let chargerOutputEnergy {
      dokoResponses[.chargerOutputEnergy] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerOutputEnergy(chargerOutputEnergy))
    }
    //### review this

    return DokoResponsePacket(type: .acChargeEnergy, responses: dokoResponses)
  }

  func acChargeHistoryResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let energyToEmpty = responsePacket.batteryEnergyToEmpty,
      let stateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.acChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeHistory, response: .error("arguments"))
      return DokoResponsePacket(type: .acChargeHistory, responses: dokoResponses)
    }
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: .acChargeHistory, response: .batteryEnergyToEmpty(energyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .acChargeHistory, response: .batteryStateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .acChargeHistory, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .acChargeHistory, response: .couplerTemperature(couplerTemperature))
    
    if let batteryPower {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeHistory, response: .batteryPower(batteryPower))
    }
    if let batteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeHistory, response: .batteryEnergy(batteryEnergy))
    }
    
    if let chargerInputPower {
      dokoResponses[.chargerInputPower] = DokoCommandResponse(command: .acChargeHistory, response: .chargerInputPower(chargerInputPower))
    }
    if let chargerInputEnergy {
      dokoResponses[.chargerInputEnergy] = DokoCommandResponse(command: .acChargeHistory, response: .chargerInputEnergy(chargerInputEnergy))
    }
    if let chargerOutputPower {
      dokoResponses[.chargerOutputPower] = DokoCommandResponse(command: .acChargeHistory, response: .chargerOutputPower(chargerOutputPower))
    }
    if let chargerOutputEnergy {
      dokoResponses[.chargerOutputEnergy] = DokoCommandResponse(command: .acChargeHistory, response: .chargerOutputEnergy(chargerOutputEnergy))
    }
    //###
    
    return DokoResponsePacket(type: .acChargeHistory, responses: dokoResponses)
  }
}
