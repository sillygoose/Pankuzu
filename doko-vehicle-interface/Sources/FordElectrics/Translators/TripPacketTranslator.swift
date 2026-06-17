import OSLog

import DokoTypes
import ObdLinkCore
import DokoWeatherManager

extension FordElectrics {
  func tripStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .tripStarting
    let dokoCommand: DokoCommand = .tripStarting
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let batteryEnergyToEmpty = responsePacket.batteryEnergyToEmpty,
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache = [:]; responseCache.merge(dokoResponses) { _, new in new } }

    duration.reset()
    tripOdometer.setOdometer(with: odometer)
    hvBatteryEnergy.reset()
    meanTemperature.reset()

    tripEfficiency.reset()

    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.tripInProgress))
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(duration.duration))
    dokoResponses[.position] = DokoCommandResponse(command: dokoCommand, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: dokoCommand, response: .odometer(tripOdometer.odometer))
    dokoResponses[.distance] = DokoCommandResponse(command: dokoCommand, response: .odometer(tripOdometer.distance))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergyToEmpty(batteryEnergyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))

    if let batteryStateOfHealth = responsePacket.batteryStateOfHealth {
      dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfHealth(batteryStateOfHealth))
    }
    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    if let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(hvBatteryEnergy))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }
  
  func tripInProgressResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .tripInProgress
    let dokoCommand: DokoCommand = .tripInProgress
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let gearSelected = responsePacket.gearSelected
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    duration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(duration.duration))

    let nextState: VehicleState = gearSelected ? .tripInProgress: .tripEnding
    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(nextState))
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }
  
  func tripEndingResponsePacket(_ responsePacket: ObdResponsePacket) async -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .tripEnding
    let dokoCommand: DokoCommand = .tripEnding
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let batteryEnergyToEmpty = responsePacket.batteryEnergyToEmpty,
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    duration.update()
    tripOdometer.updateOdometer(with: odometer)

    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.idle))
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(duration.duration))
    dokoResponses[.position] = DokoCommandResponse(command: dokoCommand, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: dokoCommand, response: .odometer(tripOdometer.odometer))
    dokoResponses[.distance] = DokoCommandResponse(command: dokoCommand, response: .distance(tripOdometer.distance))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergyToEmpty(batteryEnergyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))

    if let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(hvBatteryEnergy))
    }
    if let batteryStateOfHealth = responsePacket.batteryStateOfHealth {
      dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfHealth(batteryStateOfHealth))
    }
    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    if let weather = responsePacket.weather {
      meanTemperature.updateMeanTemperature(with: weather.temperature)
      dokoResponses[.weather] = DokoCommandResponse(command: dokoCommand, response: .weather(weather))
    }
    else if let latestWeather = await DokoWeatherManager.shared.latestWeather {
      meanTemperature.updateMeanTemperature(with: latestWeather.temperature)
      dokoResponses[.weather] = DokoCommandResponse(command: dokoCommand, response: .weather(latestWeather))
    }
    if let meanTemperature = meanTemperature.mean {
      dokoResponses[.meanTemperature] = DokoCommandResponse(command: dokoCommand, response: .meanTemperature(meanTemperature))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  func tripUpdateResponsePacket(_ responsePacket: ObdResponsePacket) async -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .tripUpdate
    return DokoResponsePacket(type: dokoPacket, responses: responseCache)
  }

  func tripEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .tripEnergy
    let dokoCommand: DokoCommand = .tripEnergy
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryVoltage = responsePacket.batteryVoltage,
      let batteryCurrent = responsePacket.batteryCurrent
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    duration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(duration.duration))

    if let batteryEnergy = hvBatteryEnergy.integrate(voltage: batteryVoltage, current: batteryCurrent, at: responsePacket.completedAt), let batteryPower = hvBatteryEnergy.power {
      dokoResponses[.batteryVoltage] = DokoCommandResponse(command: dokoCommand, response: .batteryVoltage(batteryVoltage))
      dokoResponses[.batteryCurrent] = DokoCommandResponse(command: dokoCommand, response: .batteryCurrent(batteryCurrent))
      dokoResponses[.batteryPower] = DokoCommandResponse(command: dokoCommand, response: .batteryPower(batteryPower))
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(batteryEnergy))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  func tripDataResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .tripData
    let dokoCommand: DokoCommand = .tripData
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.batteryEnergyToEmpty,
      let stateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    duration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(duration.duration))
    tripOdometer.updateOdometer(with: odometer)

    dokoResponses[.odometer] = DokoCommandResponse(command: dokoCommand, response: .odometer(tripOdometer.odometer))
    dokoResponses[.distance] = DokoCommandResponse(command: dokoCommand, response: .distance(tripOdometer.distance))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergyToEmpty(energyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))

    tripEfficiency.updateEfficiency(tripOdometer.distance, hvBatteryEnergy.energy ?? 0)
    dokoResponses[.tripEfficiency] = DokoCommandResponse(command: dokoCommand, response: .tripEfficiency(tripEfficiency.efficiency))
    dokoResponses[.tripEfficiency5Minute] = DokoCommandResponse(command: dokoCommand, response: .tripEfficiency5Minute(tripEfficiency.efficiency5min))
    dokoResponses[.tripEfficiency10Minute] = DokoCommandResponse(command: dokoCommand, response: .tripEfficiency10Minute(tripEfficiency.efficiency10min))
    dokoResponses[.tripEfficiency15Minute] = DokoCommandResponse(command: dokoCommand, response: .tripEfficiency15Minute(tripEfficiency.efficiency15min))

    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    if let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(hvBatteryEnergy))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }
  
  func tripWeatherResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .tripWeather
    let dokoCommand: DokoCommand = .tripWeather
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let weather = responsePacket.weather
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    duration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(duration.duration))

    let newMeanTemperature = meanTemperature.updateMeanTemperature(with: weather.temperature)
    dokoResponses[.weather] = DokoCommandResponse(command: dokoCommand, response: .weather(weather))
    dokoResponses[.meanTemperature] = DokoCommandResponse(command: dokoCommand, response: .meanTemperature(newMeanTemperature))
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }
}
