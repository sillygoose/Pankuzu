import OSLog

import DokoTypes
import ObdLinkCore

extension FordMachE {
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

    responseCache = [:]
    hvBatteryEnergy.reset()
    chargerInputEnergy.reset()
    chargerOutputEnergy.reset()

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
    if let batteryVoltage = hvBatteryEnergy.voltage, let batteryCurrent = hvBatteryEnergy.current {
      dokoResponses[.batteryVoltage] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryVoltage(batteryVoltage))
      dokoResponses[.batteryCurrent] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryCurrent(batteryCurrent))
    }
    if let batteryPower = hvBatteryEnergy.power, let batteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryPower(batteryPower))
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryEnergy(batteryEnergy))
    }

    if let inputVoltage = chargerInputEnergy.voltage, let inputCurrent = chargerInputEnergy.current {
      dokoResponses[.chargerInputVoltage] = DokoCommandResponse(command: .acChargeUpdate, response: .chargerInputVoltage(inputVoltage))
      dokoResponses[.chargerInputCurrent] = DokoCommandResponse(command: .acChargeUpdate, response: .chargerInputCurrent(inputCurrent))
    }
    if let inputPower = chargerInputEnergy.power, let inputEnergy = chargerInputEnergy.energy {
      dokoResponses[.chargerInputPower] = DokoCommandResponse(command: .acChargeUpdate, response: .chargerInputPower(inputPower))
      dokoResponses[.chargerInputEnergy] = DokoCommandResponse(command: .acChargeUpdate, response: .chargerInputEnergy(inputEnergy))
    }

    if let outputVoltage = chargerOutputEnergy.voltage, let outputCurrent = chargerOutputEnergy.current {
      dokoResponses[.chargerOutputVoltage] = DokoCommandResponse(command: .acChargeUpdate, response: .chargerOutputVoltage(outputVoltage))
      dokoResponses[.chargerOutputCurrent] = DokoCommandResponse(command: .acChargeUpdate, response: .chargerOutputCurrent(outputCurrent))
    }
    if let outputPower = chargerOutputEnergy.power, let outputEnergy = chargerOutputEnergy.energy {
      dokoResponses[.chargerOutputPower] = DokoCommandResponse(command: .acChargeUpdate, response: .chargerOutputPower(outputPower))
      dokoResponses[.chargerOutputEnergy] = DokoCommandResponse(command: .acChargeUpdate, response: .chargerOutputEnergy(outputEnergy))
    }

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

    if let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeEnding, response: .batteryEnergy(hvBatteryEnergy))
    }
    return DokoResponsePacket(type: .acChargeEnding, responses: dokoResponses)
  }

  func acChargeEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    
    if let batteryVoltage = responsePacket.batteryVoltage, let batteryCurrent = responsePacket.batteryCurrent {
      if let batteryEnergy = hvBatteryEnergy.integrate(voltage: batteryVoltage, current: batteryCurrent, at: responsePacket.completedAt), let batteryPower = hvBatteryEnergy.power {
        dokoResponses[.batteryVoltage] = DokoCommandResponse(command: .acChargeEnergy, response: .batteryVoltage(batteryVoltage))
        dokoResponses[.batteryCurrent] = DokoCommandResponse(command: .acChargeEnergy, response: .batteryCurrent(batteryCurrent))
        dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeEnergy, response: .batteryPower(batteryPower))
        dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeEnergy, response: .batteryEnergy(batteryEnergy))
      }
    }

    if let inputVoltage = responsePacket.chargerInputVoltage, let inputCurrent = responsePacket.chargerInputCurrent {
      if let inputEnergy = chargerInputEnergy.integrate(voltage: inputVoltage, current: inputCurrent, at: responsePacket.completedAt), let inputPower = chargerInputEnergy.power {
        dokoResponses[.chargerInputVoltage] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerInputVoltage(inputVoltage))
        dokoResponses[.chargerInputCurrent] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerInputCurrent(inputCurrent))
        dokoResponses[.chargerInputPower] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerInputPower(inputPower))
        dokoResponses[.chargerInputEnergy] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerInputEnergy(inputEnergy))
      }
    }

    if let outputVoltage = responsePacket.chargerOutputVoltage, let outputCurrent = responsePacket.chargerOutputCurrent {
      if let outputEnergy = chargerOutputEnergy.integrate(voltage: outputVoltage, current: outputCurrent, at: responsePacket.completedAt), let outputPower = chargerOutputEnergy.power {
        dokoResponses[.chargerOutputVoltage] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerOutputVoltage(outputVoltage))
        dokoResponses[.chargerOutputCurrent] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerOutputCurrent(outputCurrent))
        dokoResponses[.chargerOutputPower] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerOutputPower(outputPower))
        dokoResponses[.chargerOutputEnergy] = DokoCommandResponse(command: .acChargeEnergy, response: .chargerOutputEnergy(outputEnergy))
      }
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

    if let hvBatteryPower = hvBatteryEnergy.power, let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeHistory, response: .batteryPower(hvBatteryPower))
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeHistory, response: .batteryEnergy(hvBatteryEnergy))
    }

    if let chargerInputPower = chargerInputEnergy.power, let chargerInputEnergy = chargerInputEnergy.energy {
      dokoResponses[.chargerInputEnergy] = DokoCommandResponse(command: .acChargeHistory, response: .chargerInputEnergy(chargerInputPower))
      dokoResponses[.chargerInputEnergy] = DokoCommandResponse(command: .acChargeHistory, response: .chargerInputEnergy(chargerInputEnergy))
    }

    if let chargerOutputPower = chargerOutputEnergy.power, let chargerOutputEnergy = chargerOutputEnergy.energy {
      dokoResponses[.chargerInputEnergy] = DokoCommandResponse(command: .acChargeHistory, response: .chargerInputEnergy(chargerOutputPower))
      dokoResponses[.chargerOutputEnergy] = DokoCommandResponse(command: .acChargeHistory, response: .chargerOutputEnergy(chargerOutputEnergy))
    }

    return DokoResponsePacket(type: .acChargeHistory, responses: dokoResponses)
  }
}
