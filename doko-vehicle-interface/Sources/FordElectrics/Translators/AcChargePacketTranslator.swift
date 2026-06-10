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
    
    //### make a function
    hvBatteryPower = nil
    hvBatteryEnergy = nil
    previousHvBatteryPower = nil
    previousHvBatteryPowerUpdate = nil

    chargerInputPower = nil
    chargerInputEnergy = nil
    previousChargerInputPower = nil
    previousChargerInputPowerUpdate = nil

    chargerOutputPower = nil
    chargerOutputEnergy = nil
    previousChargerOutputPower = nil
    previousChargerOutputPowerUpdate = nil
    
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
    //###Not needed iin update, only energy
    if let batteryVoltage = responsePacket.batteryVoltage, let batteryCurrent = responsePacket.batteryCurrent {
      dokoResponses[.batteryVoltage] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryVoltage(batteryVoltage))
      dokoResponses[.batteryCurrent] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryCurrent(batteryCurrent))
    }
    if let hvBatteryPower {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryPower(hvBatteryPower))
    }
    if let hvBatteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryEnergy(hvBatteryEnergy))
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
    if let hvBatteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeEnding, response: .batteryEnergy(hvBatteryEnergy))
    }
    return DokoResponsePacket(type: .acChargeEnding, responses: dokoResponses)
  }

  func acChargeEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    
    if let batteryVoltage = responsePacket.batteryVoltage, let batteryCurrent = responsePacket.batteryCurrent {
      let batteryPower = batteryVoltage * batteryCurrent * 0.001
      hvBatteryPower = batteryPower
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeEnergy, response: .batteryPower(batteryPower))
      if let previousTime = previousHvBatteryPowerUpdate, let previousHvBattryPower = previousHvBatteryPower {
        let deltaHours = responsePacket.completedAt.timeIntervalSince(previousTime) / 3600.0
        let batteryEnergy = (hvBatteryEnergy ?? 0.0) + (previousHvBattryPower + batteryPower) / 2.0 * deltaHours
        dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeEnergy, response: .batteryEnergy(batteryEnergy))
        hvBatteryEnergy = batteryEnergy
      }
      previousHvBatteryPower = batteryPower
      previousHvBatteryPowerUpdate = responsePacket.completedAt
    }

    if let chargerInputVoltage = responsePacket.chargerInputVoltage, let chargerInputCurrent = responsePacket.chargerInputCurrent {
      let inputPower = chargerInputVoltage * chargerInputCurrent * 0.001
      chargerInputPower = inputPower
      dokoResponses[.chargerInputPower] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerInputPower(inputPower))
      if let previousUpdate = previousChargerInputPowerUpdate, let previousChargerInputPower = previousChargerInputPower {
        let deltaHours = responsePacket.completedAt.timeIntervalSince(previousUpdate) / 3600.0
        let inputEnergy = (chargerInputEnergy ?? 0.0) + (previousChargerInputPower + inputPower) / 2.0 * deltaHours
        dokoResponses[.chargerInputEnergy] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerInputEnergy(inputEnergy))
        chargerInputEnergy = inputEnergy
      }
      previousChargerInputPower = inputPower
      previousChargerInputPowerUpdate = responsePacket.completedAt
    }

    if let chargerOutputVoltage = responsePacket.chargerOutputVoltage, let chargerOutputCurrent = responsePacket.chargerOutputCurrent {
      let outputPower = chargerOutputVoltage * chargerOutputCurrent * 0.001
      chargerOutputPower = outputPower
      dokoResponses[.chargerOutputPower] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerOutputPower(outputPower))
      if let previousUpdate = previousChargerOutputPowerUpdate, let previousChargerOutputPower = previousChargerOutputPower {
        let deltaHours = responsePacket.completedAt.timeIntervalSince(previousUpdate) / 3600.0
        let outputEnergy = (chargerOutputEnergy ?? 0.0) + (previousChargerOutputPower + outputPower) / 2.0 * deltaHours
        dokoResponses[.chargerOutputEnergy] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerOutputEnergy(outputEnergy))
        chargerOutputEnergy = outputEnergy
      }
      previousChargerOutputPower = outputPower
      previousChargerOutputPowerUpdate = responsePacket.completedAt
    }

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
    
    if let hvBatteryPower {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeHistory, response: .batteryPower(hvBatteryPower))
    }
    if let hvBatteryEnergy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeHistory, response: .batteryEnergy(hvBatteryEnergy))
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
