import OSLog

import DokoTypes
import ObdLinkCore

extension VwElectrics {
  func dcChargeStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .dcChargeStarting
    let dokoCommand: DokoCommand = .dcChargeStarting
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache = [:]; responseCache.merge(dokoResponses) { _, new in new } }

    hvBatteryEnergy.reset()

    vehicleOdometer.setOdometer(with: odometer)
    dokoResponses[.odometer] = DokoCommandResponse(command: dokoCommand, response: .odometer(odometer))

    vehicleDuration.reset()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.dcChargeInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: dokoCommand, response: .position(position))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))

    if let weather = responsePacket.weather {
      dokoResponses[.weather] = DokoCommandResponse(command: dokoCommand, response: .weather(weather))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  func dcChargeInProgressResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
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

    let nextState: VehicleState = dcChargerStatus ? .dcChargeInProgress: .dcChargeEnding
    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(nextState))
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  func dcChargeEndingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .dcChargeEnding
    let dokoCommand: DokoCommand = .dcChargeEnding
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.idle))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))

    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(hvBatteryEnergy.energy))
    
    if let batteryTemperature = responsePacket.batteryTemperature {
      dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))
    }
    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    if let batteryCurrentCapacity = responsePacket.batteryCurrentCapacity, let batteryOriginalCapacity = responsePacket.batteryOriginalCapacity, batteryOriginalCapacity > 0 {
      let batteryStateOfHealth = 100 * batteryCurrentCapacity / batteryOriginalCapacity
      dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfHealth(batteryStateOfHealth))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  func dcChargeUpdateResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .dcChargeUpdate
    return DokoResponsePacket(type: dokoPacket, responses: responseCache)
  }

  func dcChargeEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
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
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  func dcChargeHistoryResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .dcChargeHistory
    let dokoCommand: DokoCommand = .dcChargeHistory
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))

    if let hvBatteryPower = hvBatteryEnergy.power {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: dokoCommand, response: .batteryPower(hvBatteryPower))
    }
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(hvBatteryEnergy.energy))

    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }
}
