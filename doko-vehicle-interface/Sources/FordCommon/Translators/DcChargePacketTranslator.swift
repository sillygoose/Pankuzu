import DokoTypes
import ObdLinkCore

extension FordTranslating {
  public func dcChargeStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .dcChargeStarting
    let dokoCommand: DokoCommand = .dcChargeStarting
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let batteryEnergyToEmpty = responsePacket.batteryEnergyToEmpty,
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryStateOfHealth = responsePacket.batteryStateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature1 = responsePacket.dcChargerCouplerTemperature1,
      let couplerTemperature3 = responsePacket.dcChargerCouplerTemperature3
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache = [:]; responseCache.merge(dokoResponses) { _, new in new } }

    hvBatteryEnergy.reset()
    chargerInputEnergy.reset()
    chargerOutputEnergy.reset()

    vehicleOdometer.setOdometer(with: odometer)
    dokoResponses[.odometer] = DokoCommandResponse(command: dokoCommand, response: .odometer(odometer))

    vehicleDuration.reset()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.dcChargeInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: dokoCommand, response: .position(position))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergyToEmpty(batteryEnergyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfHealth(batteryStateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))

    let couplerTemperature = (couplerTemperature1 + couplerTemperature3) / 2
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: dokoCommand, response: .couplerTemperature(couplerTemperature))
    dokoResponses[.primaryCouplerTemperature] = DokoCommandResponse(command: dokoCommand, response: .primaryCouplerTemperature(couplerTemperature1))
    dokoResponses[.secondaryCouplerTemperature] = DokoCommandResponse(command: dokoCommand, response: .secondaryCouplerTemperature(couplerTemperature3))

    if let weather = responsePacket.weather {
      dokoResponses[.weather] = DokoCommandResponse(command: dokoCommand, response: .weather(weather))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  public func dcChargeInProgressResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .dcChargeInProgress
    let dokoCommand: DokoCommand = .dcChargeInProgress
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let dcChargerStatus = responsePacket.dcChargerStatus
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    let nextState: VehicleState = dcChargerStatus ? .dcChargeInProgress : .dcChargeEnding
    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(nextState))
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  public func dcChargeEndingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .dcChargeEnding
    let dokoCommand: DokoCommand = .dcChargeEnding
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryEnergyToEmpty = responsePacket.batteryEnergyToEmpty,
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryStateOfHealth = responsePacket.batteryStateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature1 = responsePacket.dcChargerCouplerTemperature1,
      let couplerTemperature3 = responsePacket.dcChargerCouplerTemperature3
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.idle))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergyToEmpty(batteryEnergyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfHealth(batteryStateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))

    let couplerTemperature = (couplerTemperature1 + couplerTemperature3) / 2
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: dokoCommand, response: .couplerTemperature(couplerTemperature))
    dokoResponses[.primaryCouplerTemperature] = DokoCommandResponse(command: dokoCommand, response: .primaryCouplerTemperature(couplerTemperature1))
    dokoResponses[.secondaryCouplerTemperature] = DokoCommandResponse(command: dokoCommand, response: .secondaryCouplerTemperature(couplerTemperature3))

    if let e = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(e))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  public func dcChargeUpdateResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .dcChargeUpdate
    return DokoResponsePacket(type: dokoPacket, responses: responseCache)
  }

  public func dcChargeEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .dcChargeEnergy
    let dokoCommand: DokoCommand = .dcChargeEnergy
    var dokoResponses: DokoResponseDictionary = [:]
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    if let batteryVoltage = responsePacket.batteryVoltage, let batteryCurrent = responsePacket.batteryCurrent {
      if let batteryEnergy = hvBatteryEnergy.integrate(voltage: batteryVoltage, current: batteryCurrent, at: responsePacket.completedAt), let batteryPower = hvBatteryEnergy.power {
        dokoResponses[.batteryVoltage] = DokoCommandResponse(command: dokoCommand, response: .batteryVoltage(batteryVoltage))
        dokoResponses[.batteryCurrent] = DokoCommandResponse(command: dokoCommand, response: .batteryCurrent(batteryCurrent))
        dokoResponses[.batteryPower] = DokoCommandResponse(command: dokoCommand, response: .batteryPower(batteryPower))
        dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(batteryEnergy))
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

  public func dcChargeHistoryResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .dcChargeHistory
    let dokoCommand: DokoCommand = .dcChargeHistory
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryEnergyToEmpty = responsePacket.batteryEnergyToEmpty,
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature1 = responsePacket.dcChargerCouplerTemperature1,
      let couplerTemperature3 = responsePacket.dcChargerCouplerTemperature3
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergyToEmpty(batteryEnergyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))

    let couplerTemperature = (couplerTemperature1 + couplerTemperature3) / 2
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .couplerTemperature(couplerTemperature))
    dokoResponses[.primaryCouplerTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .primaryCouplerTemperature(couplerTemperature1))
    dokoResponses[.secondaryCouplerTemperature] = DokoCommandResponse(command: .dcChargeStarting, response: .secondaryCouplerTemperature(couplerTemperature3))

    if let voltageRequested = responsePacket.batteryChargeVoltageRequested {
      dokoResponses[.batteryChargeVoltageRequested] = DokoCommandResponse(command: dokoCommand, response: .batteryChargeVoltageRequested(voltageRequested))
    }
    if let currentRequested = responsePacket.batteryChargeCurrentRequested {
      dokoResponses[.batteryChargeCurrentRequested] = DokoCommandResponse(command: dokoCommand, response: .batteryChargeCurrentRequested(currentRequested))
    }

    if let power = hvBatteryEnergy.power {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: dokoCommand, response: .batteryPower(power))
    }
    if let energy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(energy))
    }
    if let power = chargerOutputEnergy.power {
      dokoResponses[.chargerOutputPower] = DokoCommandResponse(command: dokoCommand, response: .chargerOutputPower(power))
    }
    if let energy = chargerOutputEnergy.energy {
      dokoResponses[.chargerOutputEnergy] = DokoCommandResponse(command: dokoCommand, response: .chargerOutputEnergy(energy))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }
}
