import DokoTypes
import ObdLinkCore
import DokoWeatherManager

extension FordTranslating {
  public func tripStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
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

    vehicleMeanTemperature.reset()
    hvBatteryEnergy.reset()

    let duration = vehicleDuration.reset()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(duration))

    let distance = vehicleOdometer.setOdometer(with: odometer)
    dokoResponses[.odometer] = DokoCommandResponse(command: dokoCommand, response: .odometer(odometer))
    dokoResponses[.distance] = DokoCommandResponse(command: dokoCommand, response: .odometer(distance))

    let efficiency = vehicleEfficiency.reset()
    dokoResponses[.tripEfficiency] = DokoCommandResponse(command: dokoCommand, response: .tripEfficiency(efficiency))

    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.tripInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: dokoCommand, response: .position(position))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergyToEmpty(batteryEnergyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))

    if let batteryStateOfHealth = responsePacket.batteryStateOfHealth {
      dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfHealth(batteryStateOfHealth))
    }
    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  public func tripInProgressResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
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

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    let nextState: VehicleState = gearSelected ? .tripInProgress : .tripEnding
    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(nextState))
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  public func tripEndingResponsePacket(_ responsePacket: ObdResponsePacket) async -> DokoResponsePacket {
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

    vehicleDuration.update()
    vehicleOdometer.updateOdometer(with: odometer)

    dokoResponses[.nextState] = DokoCommandResponse(command: dokoCommand, response: .nextState(.idle))
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))
    dokoResponses[.position] = DokoCommandResponse(command: dokoCommand, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: dokoCommand, response: .odometer(vehicleOdometer.odometer))
    dokoResponses[.distance] = DokoCommandResponse(command: dokoCommand, response: .distance(vehicleOdometer.distance))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergyToEmpty(batteryEnergyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))

    if let e = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(e))
    }
    if let batteryStateOfHealth = responsePacket.batteryStateOfHealth {
      dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfHealth(batteryStateOfHealth))
    }
    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }

    if let weather = responsePacket.weather {
      vehicleMeanTemperature.updateMeanTemperature(with: weather.temperature)
      dokoResponses[.weather] = DokoCommandResponse(command: dokoCommand, response: .weather(weather))
    } else if let latestWeather = await DokoWeatherManager.shared.latestWeather {
      vehicleMeanTemperature.updateMeanTemperature(with: latestWeather.temperature)
      dokoResponses[.weather] = DokoCommandResponse(command: dokoCommand, response: .weather(latestWeather))
    }
    if let meanTemperature = vehicleMeanTemperature.mean {
      dokoResponses[.meanTemperature] = DokoCommandResponse(command: dokoCommand, response: .meanTemperature(meanTemperature))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  public func tripUpdateResponsePacket(_ responsePacket: ObdResponsePacket) async -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .tripUpdate
    let dokoCommand: DokoCommand = .tripUpdate
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    dokoResponses[.position] = DokoCommandResponse(command: dokoCommand, response: .position(position))
    return DokoResponsePacket(type: dokoPacket, responses: responseCache)
  }

  public func tripEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
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

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    if let batteryEnergy = hvBatteryEnergy.integrate(voltage: batteryVoltage, current: batteryCurrent, at: responsePacket.completedAt), let batteryPower = hvBatteryEnergy.power {
      dokoResponses[.batteryVoltage] = DokoCommandResponse(command: dokoCommand, response: .batteryVoltage(batteryVoltage))
      dokoResponses[.batteryCurrent] = DokoCommandResponse(command: dokoCommand, response: .batteryCurrent(batteryCurrent))
      dokoResponses[.batteryPower] = DokoCommandResponse(command: dokoCommand, response: .batteryPower(batteryPower))
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(batteryEnergy))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  public func tripDataResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    let dokoPacket: DokoPacketType = .tripData
    let dokoCommand: DokoCommand = .tripData
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let odometer = responsePacket.odometer,
      let batteryEnergyToEmpty = responsePacket.batteryEnergyToEmpty,
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: dokoCommand, response: .error("arguments"))
      return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
    }
    defer { responseCache.merge(dokoResponses) { _, new in new } }

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    let distance = vehicleOdometer.updateOdometer(with: odometer)
    dokoResponses[.odometer] = DokoCommandResponse(command: dokoCommand, response: .odometer(odometer))
    dokoResponses[.distance] = DokoCommandResponse(command: dokoCommand, response: .distance(distance))

    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergyToEmpty(batteryEnergyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: dokoCommand, response: .batteryStateOfCharge(batteryStateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: dokoCommand, response: .batteryTemperature(batteryTemperature))

    let efficieency = vehicleEfficiency.updateEfficiency(distance, -(hvBatteryEnergy.energy ?? 0))
    dokoResponses[.tripEfficiency] = DokoCommandResponse(command: dokoCommand, response: .tripEfficiency(efficieency))
    if let efficiency5min = vehicleEfficiency.efficiency5min {
      dokoResponses[.tripEfficiency5Minute] = DokoCommandResponse(command: dokoCommand, response: .tripEfficiency5Minute(efficiency5min))
    }
    if let efficiency10min = vehicleEfficiency.efficiency10min {
      dokoResponses[.tripEfficiency10Minute] = DokoCommandResponse(command: dokoCommand, response: .tripEfficiency10Minute(efficiency10min))
    }
    if let efficiency15min = vehicleEfficiency.efficiency15min {
      dokoResponses[.tripEfficiency15Minute] = DokoCommandResponse(command: dokoCommand, response: .tripEfficiency15Minute(efficiency15min))
    }

    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: dokoCommand, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    if let e = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: dokoCommand, response: .batteryEnergy(e))
    }
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }

  public func tripWeatherResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
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

    vehicleDuration.update()
    dokoResponses[.duration] = DokoCommandResponse(command: dokoCommand, response: .duration(vehicleDuration.duration))

    let newMeanTemperature = vehicleMeanTemperature.updateMeanTemperature(with: weather.temperature)
    dokoResponses[.meanTemperature] = DokoCommandResponse(command: dokoCommand, response: .meanTemperature(newMeanTemperature))
    dokoResponses[.weather] = DokoCommandResponse(command: dokoCommand, response: .weather(weather))
    return DokoResponsePacket(type: dokoPacket, responses: dokoResponses)
  }
}
