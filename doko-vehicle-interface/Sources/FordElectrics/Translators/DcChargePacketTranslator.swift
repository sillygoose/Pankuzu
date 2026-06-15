import OSLog

import DokoTypes
import ObdLinkCore

extension FordElectrics {
  func dcChargeStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.batteryEnergyToEmpty,
      let stateOfCharge = responsePacket.batteryStateOfCharge,
      let stateOfHealth = responsePacket.batteryStateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature1 = responsePacket.dcChargerCouplerTemperature1,
      let couplerTemperature3 = responsePacket.dcChargerCouplerTemperature3
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeStarting, response: .error("arguments"))
      return DokoResponsePacket(type: .dcChargeStarting, responses: dokoResponses)
    }
    defer { responseCache = dokoResponses }

    hvBatteryEnergy.reset()
    chargerInputEnergy.reset()
    chargerOutputEnergy.reset()

    dokoResponses[.nextState] = DokoCommandResponse(command: .dcChargeStarting, response: .nextState(.dcChargeInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: .dcChargeStarting, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: .dcChargeStarting, response: .odometer(odometer))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: .dcChargeStarting, response: .batteryEnergyToEmpty(energyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .dcChargeStarting, response: .batteryStateOfCharge(stateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .dcChargeStarting, response: .batteryStateOfHealth(stateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .batteryTemperature(batteryTemperature))

    let couplerTemperature = (couplerTemperature1 + couplerTemperature3) / 2
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .couplerTemperature(couplerTemperature))
    dokoResponses[.primaryCouplerTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .primaryCouplerTemperature(couplerTemperature1))
    dokoResponses[.secondaryCouplerTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .secondaryCouplerTemperature(couplerTemperature3))
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
//    var dokoResponses: DokoResponseDictionary = [:]
//    if let batteryVoltage = hvBatteryEnergy.voltage, let batteryCurrent = hvBatteryEnergy.current {
//      dokoResponses[.batteryVoltage] = DokoCommandResponse(command: .dcChargeUpdate, response: .batteryVoltage(batteryVoltage))
//      dokoResponses[.batteryCurrent] = DokoCommandResponse(command: .dcChargeUpdate, response: .batteryCurrent(batteryCurrent))
//    }
//    if let batteryPower = hvBatteryEnergy.power, let batteryEnergy = hvBatteryEnergy.energy {
//      dokoResponses[.batteryPower] = DokoCommandResponse(command: .dcChargeUpdate, response: .batteryPower(batteryPower))
//      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeUpdate, response: .batteryEnergy(batteryEnergy))
//    }
//
//    if let outputVoltage = chargerOutputEnergy.voltage, let outputCurrent = chargerOutputEnergy.current {
//      dokoResponses[.chargerOutputVoltage] = DokoCommandResponse(command: .dcChargeUpdate, response: .chargerOutputVoltage(outputVoltage))
//      dokoResponses[.chargerOutputCurrent] = DokoCommandResponse(command: .dcChargeUpdate, response: .chargerOutputCurrent(outputCurrent))
//    }
//    if let outputPower = chargerOutputEnergy.power, let outputEnergy = chargerOutputEnergy.energy {
//      dokoResponses[.chargerOutputPower] = DokoCommandResponse(command: .dcChargeUpdate, response: .chargerOutputPower(outputPower))
//      dokoResponses[.chargerOutputEnergy] = DokoCommandResponse(command: .dcChargeUpdate, response: .chargerOutputEnergy(outputEnergy))
//    }
//
//    if let stateOfCharge = responsePacket.batteryStateOfCharge {
//      dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .dcChargeUpdate, response: .batteryStateOfCharge(stateOfCharge))
//    }
//    if let batteryTemperature = responsePacket.batteryTemperature {
//      dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .dcChargeUpdate, response: .batteryTemperature(batteryTemperature))
//    }
//    if let couplerTemperature = responsePacket.dcChargerCouplerTemperature1 {
//      dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .dcChargeUpdate, response: .couplerTemperature(couplerTemperature))
//    }
    return DokoResponsePacket(type: .dcChargeUpdate, responses: responseCache)
  }

  func dcChargeEndingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let energyToEmpty = responsePacket.batteryEnergyToEmpty,
      let stateOfCharge = responsePacket.batteryStateOfCharge,
      let stateOfHealth = responsePacket.batteryStateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.dcChargerCouplerTemperature1
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeEnding, response: .error("arguments"))
      return DokoResponsePacket(type: .dcChargeEnding, responses: dokoResponses)
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .dcChargeEnding, response: .nextState(.idle))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: .dcChargeEnding, response: .batteryEnergyToEmpty(energyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .dcChargeEnding, response: .batteryStateOfCharge(stateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .dcChargeEnding, response: .batteryStateOfHealth(stateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .dcChargeEnding, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .dcChargeEnding, response: .couplerTemperature(couplerTemperature))

    if let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeEnding, response: .batteryEnergy(hvBatteryEnergy))
    }
    return DokoResponsePacket(type: .dcChargeEnding, responses: dokoResponses)
  }

  func dcChargeEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    if let batteryVoltage = responsePacket.batteryVoltage, let batteryCurrent = responsePacket.batteryCurrent {
      if let batteryEnergy = hvBatteryEnergy.integrate(voltage: batteryVoltage, current: batteryCurrent, at: responsePacket.completedAt), let batteryPower = hvBatteryEnergy.power {
        dokoResponses[.batteryVoltage] = DokoCommandResponse(command: .dcChargeEnergy, response: .batteryVoltage(batteryVoltage))
        dokoResponses[.batteryCurrent] = DokoCommandResponse(command: .dcChargeEnergy, response: .batteryCurrent(batteryCurrent))
        dokoResponses[.batteryPower] = DokoCommandResponse(command: .dcChargeEnergy, response: .batteryPower(batteryPower))
        dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeEnergy, response: .batteryEnergy(batteryEnergy))
      }
    }

    if let outputVoltage = responsePacket.chargerOutputVoltage, let outputCurrent = responsePacket.chargerOutputCurrent {
      if let outputEnergy = chargerOutputEnergy.integrate(voltage: outputVoltage, current: outputCurrent, at: responsePacket.completedAt), let outputPower = chargerOutputEnergy.power {
        dokoResponses[.chargerOutputVoltage] = DokoCommandResponse(command: .dcChargeEnergy, response: .chargerOutputVoltage(outputVoltage))
        dokoResponses[.chargerOutputCurrent] = DokoCommandResponse(command: .dcChargeEnergy, response: .chargerOutputCurrent(outputCurrent))
        dokoResponses[.chargerOutputPower] = DokoCommandResponse(command: .dcChargeEnergy, response: .chargerOutputPower(outputPower))
        dokoResponses[.chargerOutputEnergy] = DokoCommandResponse(command: .dcChargeEnergy, response: .chargerOutputEnergy(outputEnergy))
      }
    }

    return DokoResponsePacket(type: .dcChargeEnergy, responses: dokoResponses)
  }

  func dcChargeHistoryPacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let energyToEmpty = responsePacket.batteryEnergyToEmpty,
      let stateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature1 = responsePacket.dcChargerCouplerTemperature1,
      let couplerTemperature3 = responsePacket.dcChargerCouplerTemperature3
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .dcChargeHistory, response: .error("arguments"))
      return DokoResponsePacket(type: .dcChargeHistory, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: .dcChargeHistory, response: .batteryEnergyToEmpty(energyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .dcChargeHistory, response: .batteryStateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .dcChargeHistory, response: .batteryTemperature(batteryTemperature))

    let couplerTemperature = (couplerTemperature1 + couplerTemperature3) / 2
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .couplerTemperature(couplerTemperature))
    dokoResponses[.primaryCouplerTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .primaryCouplerTemperature(couplerTemperature1))
    dokoResponses[.secondaryCouplerTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .secondaryCouplerTemperature(couplerTemperature3))

//    if let hvBatteryPower = hvBatteryEnergy.power, let hvBatteryEnergy = hvBatteryEnergy.energy {
//      dokoResponses[.batteryPower] = DokoCommandResponse(command: .dcChargeHistory, response: .batteryPower(hvBatteryPower))
//      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .dcChargeHistory, response: .batteryEnergy(hvBatteryEnergy))
//    }
//
//    if let chargerOutputPower = chargerOutputEnergy.power, let chargerOutputEnergy = chargerOutputEnergy.energy {
//      dokoResponses[.chargerInputEnergy] = DokoCommandResponse(command: .dcChargeHistory, response: .chargerInputEnergy(chargerOutputPower))
//      dokoResponses[.chargerOutputEnergy] = DokoCommandResponse(command: .dcChargeHistory, response: .chargerOutputEnergy(chargerOutputEnergy))
//    }

    return DokoResponsePacket(type: .dcChargeHistory, responses: dokoResponses)
  }
}
