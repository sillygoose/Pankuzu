import OSLog

import DokoTypes
import ObdLinkCore

extension VwElectrics {
  func acChargeStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .acChargeStarting
    let dokoCommand: DokoCommand = .acChargeStarting
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }

    hvBatteryEnergy.reset()
    vehicleDuration.reset()
    vehicleOdometer.resetOdometer(with: odometer, and: position)

    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.acChargeInProgress))
    dokoResponses[.odometer] = DokoCommandResponse(command: dokoCommand, response: .odometer(odometer))
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))
    dokoResponses[.position] = DokoCommandResponse(command: dokoCommand, response: .position(position))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))

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
    
    if let weather = responsePacket.weather {
      dokoResponses[.weather] = DokoCommandResponse(command: dokoCommand, response: .weather(weather))
    }
    
    responseCache.merge(dokoResponses) { _, new in new }
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

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    let nextState: VehicleState = acChargerStatus ? .acChargeInProgress: .acChargeEnding
    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(nextState))

    responseCache.merge(dokoResponses) { _, new in new }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  func acChargeEndingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .acChargeEnding
    let dokoCommand: DokoCommand = .acChargeEnding
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.idle))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))

    if let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(hvBatteryEnergy))
    }
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

  func acChargeUpdateResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .acChargeUpdate
    return DokoResponsePacket(type: dokoPacket, responses: responseCache)
  }

  func acChargeEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .acChargeEnergy
    let dokoCommand: DokoCommand = .acChargeEnergy
    var dokoResponses: DokoResponseDictionary = [:]

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

    responseCache.merge(dokoResponses) { _, new in new }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  func acChargeHistoryResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .acChargeHistory
    let dokoCommand: DokoCommand = .acChargeHistory
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))

    if let hvBatteryPower = hvBatteryEnergy.power {
      dokoResponses[.batteryPower] = DokoCommandResponse(command: dokoCommand, response: .batteryPower(hvBatteryPower))
    }
    if let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(hvBatteryEnergy))
    }
    
    responseCache.merge(dokoResponses) { _, new in new }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }
}
