import OSLog

import DokoTypes
import ObdLinkCore

extension FordElectrics {
  func acChargeStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .acChargeStarting
    let dokoCommand: DokoCommand = .acChargeStarting
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let batteryEnergyToEmpty = responsePacket.batteryEnergyToEmpty,
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryStateOfHealth = responsePacket.batteryStateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.acChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache = [:]; responseCache.merge(dokoResponses) { _, new in new } }

    hvBatteryEnergy.reset()
    chargerInputEnergy.reset()
    chargerOutputEnergy.reset()

    tripOdometer.setOdometer(with: odometer)
    dokoResponses[.odometer] = DokoCommandResponse(command: dokoCommand, response: .odometer(odometer))

    duration.reset()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(duration.duration))

    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.acChargeInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: dokoCommand, response: .position(position))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergyToEmpty(batteryEnergyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfHealth(batteryStateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: dokoCommand, response: .couplerTemperature(couplerTemperature))
    dokoResponses[.primaryCouplerTemperature] = DokoCommandResponse(command: dokoCommand, response: .primaryCouplerTemperature(couplerTemperature))
    if let weather = responsePacket.weather {
      dokoResponses[.weather] = DokoCommandResponse(command: dokoCommand, response: .weather(weather))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }
  
  func acChargeInProgressResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .acChargeInProgress
    let dokoCommand: DokoCommand = .acChargeInProgress
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let acChargerStatus = responsePacket.acChargerStatus
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    duration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(duration.duration))

    let nextState: VehicleState = acChargerStatus ? .acChargeInProgress: .acChargeEnding
    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(nextState))
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  func acChargeUpdateResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .acChargeUpdate
    return DokoResponsePacket(type: dokoPacket, responses: responseCache)
  }

  func acChargeEndingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .acChargeEnding
    let dokoCommand: DokoCommand = .acChargeEnding
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryEnergyToEmpty = responsePacket.batteryEnergyToEmpty,
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryStateOfHealth = responsePacket.batteryStateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.acChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    duration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(duration.duration))

    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.idle))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergyToEmpty(batteryEnergyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfHealth(batteryStateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: dokoCommand, response: .couplerTemperature(couplerTemperature))
    dokoResponses[.primaryCouplerTemperature] = DokoCommandResponse(command: dokoCommand, response: .primaryCouplerTemperature(couplerTemperature))
    if let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(hvBatteryEnergy))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  func acChargeEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .acChargeEnergy
    let dokoCommand: DokoCommand = .acChargeEnergy
    var dokoResponses: DokoResponseDictionary = [:]
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    duration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(duration.duration))

    if let batteryVoltage = responsePacket.batteryVoltage, let batteryCurrent = responsePacket.batteryCurrent {
      if let batteryEnergy = hvBatteryEnergy.integrate(voltage: batteryVoltage, current: batteryCurrent, at: responsePacket.completedAt), let batteryPower = hvBatteryEnergy.power {
        dokoResponses[.batteryVoltage] = DokoCommandResponse(command: dokoCommand, response: .batteryVoltage(batteryVoltage))
        dokoResponses[.batteryCurrent] = DokoCommandResponse(command: dokoCommand, response: .batteryCurrent(batteryCurrent))
        dokoResponses[.batteryPower] = DokoCommandResponse(command: dokoCommand, response: .batteryPower(batteryPower))
        dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(batteryEnergy))
      }
    }

    if let inputVoltage = responsePacket.chargerInputVoltage, let inputCurrent = responsePacket.chargerInputCurrent {
      if let inputEnergy = chargerInputEnergy.integrate(voltage: inputVoltage, current: inputCurrent, at: responsePacket.completedAt), let inputPower = chargerInputEnergy.power {
        dokoResponses[.chargerInputVoltage] = DokoCommandResponse(command: dokoCommand, response: .chargerInputVoltage(inputVoltage))
        dokoResponses[.chargerInputCurrent] = DokoCommandResponse(command: dokoCommand, response: .chargerInputCurrent(inputCurrent))
        dokoResponses[.chargerInputPower] = DokoCommandResponse(command: dokoCommand, response: .chargerInputPower(inputPower))
        dokoResponses[.peakPower] = DokoCommandResponse(command: dokoCommand, response: .peakPower(chargerInputEnergy.peakPower))
        dokoResponses[.chargerInputEnergy] = DokoCommandResponse(command: dokoCommand, response: .chargerInputEnergy(inputEnergy))
      }
    }

    if let outputVoltage = responsePacket.chargerOutputVoltage, let outputCurrent = responsePacket.chargerOutputCurrent {
      if let outputEnergy = chargerOutputEnergy.integrate(voltage: outputVoltage, current: outputCurrent, at: responsePacket.completedAt), let outputPower = chargerOutputEnergy.power {
        dokoResponses[.chargerOutputVoltage] = DokoCommandResponse(command: dokoCommand, response: .chargerOutputVoltage(outputVoltage))
        dokoResponses[.chargerOutputCurrent] = DokoCommandResponse(command: dokoCommand, response: .chargerOutputCurrent(outputCurrent))
        dokoResponses[.chargerOutputPower] = DokoCommandResponse(command: dokoCommand, response: .chargerOutputPower(outputPower))
        dokoResponses[.chargerOutputEnergy] = DokoCommandResponse(command: dokoCommand, response: .chargerOutputEnergy(outputEnergy))
      }
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  func acChargeHistoryResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .acChargeHistory
    let dokoCommand: DokoCommand = .acChargeHistory
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryEnergyToEmpty = responsePacket.batteryEnergyToEmpty,
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.acChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    duration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(duration.duration))

    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergyToEmpty(batteryEnergyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: dokoCommand, response: .couplerTemperature(couplerTemperature))
    dokoResponses[.primaryCouplerTemperature] = DokoCommandResponse(command: dokoCommand, response: .primaryCouplerTemperature(couplerTemperature))

    if let hvBatteryPower = hvBatteryEnergy.power, let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: dokoCommand, response: .batteryPower(hvBatteryPower))
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(hvBatteryEnergy))
    }
    if let chargerInputPower = chargerInputEnergy.power, let chargerInputEnergy = chargerInputEnergy.energy {
      dokoResponses[.chargerInputPower] = DokoCommandResponse(command: dokoCommand, response: .chargerInputPower(chargerInputPower))
      dokoResponses[.chargerInputEnergy] = DokoCommandResponse(command: dokoCommand, response: .chargerInputEnergy(chargerInputEnergy))
    }
    if let chargerOutputPower = chargerOutputEnergy.power, let chargerOutputEnergy = chargerOutputEnergy.energy {
      dokoResponses[.chargerOutputPower] = DokoCommandResponse(command: dokoCommand, response: .chargerOutputPower(chargerOutputPower))
      dokoResponses[.chargerOutputEnergy] = DokoCommandResponse(command: dokoCommand, response: .chargerOutputEnergy(chargerOutputEnergy))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }
}
