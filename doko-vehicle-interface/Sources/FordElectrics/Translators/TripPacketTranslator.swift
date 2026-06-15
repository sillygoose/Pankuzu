import OSLog

import DokoTypes
import ObdLinkCore
import DokoWeatherManager

extension FordElectrics {
  func tripStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.batteryEnergyToEmpty,
      let stateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripStarting, response: .error("arguments"))
      return DokoResponsePacket(type: .tripStarting, responses: dokoResponses)
    }

    hvBatteryEnergy.reset()
    meanTemperatureSum = 0.0
    meanTemperatureCount = 0
    tripOdometer.reset(odometer: odometer)

    dokoResponses[.nextState] = DokoCommandResponse(command: .tripStarting, response: .nextState(.tripInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: .tripStarting, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: .tripStarting, response: .odometer(tripOdometer.odometer))
    dokoResponses[.distance] = DokoCommandResponse(command: .tripStarting, response: .odometer(tripOdometer.distance))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: .tripStarting, response: .batteryEnergyToEmpty(energyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .tripStarting, response: .batteryStateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .tripStarting, response: .batteryTemperature(batteryTemperature))

    if let batteryStateOfHealth = responsePacket.batteryStateOfHealth {
      dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .tripStarting, response: .batteryStateOfHealth(batteryStateOfHealth))
    }
    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: .tripStarting, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    if let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripStarting, response: .batteryEnergy(hvBatteryEnergy))
    }

    return DokoResponsePacket(type: .tripStarting, responses: dokoResponses)
  }
  
  func tripInProgressResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let gearSelected = responsePacket.gearSelected
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripInProgress, response: .error("arguments"))
      return DokoResponsePacket(type: .tripInProgress, responses: dokoResponses)
    }
    let nextState: VehicleState = gearSelected ? .tripInProgress: .tripEnding
    dokoResponses[.nextState] = DokoCommandResponse(command: .tripInProgress, response: .nextState(nextState))
    return DokoResponsePacket(type: .tripInProgress, responses: dokoResponses)
  }
  
  func tripEndingResponsePacket(_ responsePacket: ObdResponsePacket) async -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.batteryEnergyToEmpty,
      let stateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripEnding, response: .error("arguments"))
      return DokoResponsePacket(type: .tripEnding, responses: dokoResponses)
    }
    tripOdometer.update(odometer: odometer)

    dokoResponses[.nextState] = DokoCommandResponse(command: .tripEnding, response: .nextState(.idle))
    dokoResponses[.position] = DokoCommandResponse(command: .tripEnding, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: .tripEnding, response: .odometer(odometer))
    dokoResponses[.distance] = DokoCommandResponse(command: .tripEnding, response: .distance(tripOdometer.distance))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: .tripEnding, response: .batteryEnergyToEmpty(energyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .tripEnding, response: .batteryStateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .tripEnding, response: .batteryTemperature(batteryTemperature))

    if let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripEnding, response: .batteryEnergy(hvBatteryEnergy))
    }
    if let batteryStateOfHealth = responsePacket.batteryStateOfHealth {
      dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .tripEnding, response: .batteryStateOfHealth(batteryStateOfHealth))
    }
    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: .tripEnding, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    if let weather = responsePacket.weather {
      meanTemperatureSum += weather.temperature
      meanTemperatureCount += 1
      dokoResponses[.weather] = DokoCommandResponse(command: .tripEnding, response: .weather(weather))
    }
    else if let latestWeather = await DokoWeatherManager.shared.latestWeather {
      meanTemperatureSum += latestWeather.temperature
      meanTemperatureCount += 1
      dokoResponses[.weather] = DokoCommandResponse(command: .tripEnding, response: .weather(latestWeather))
    }
    if meanTemperatureCount > 0 {
      let meanTemperature = meanTemperatureSum / Double(meanTemperatureCount)
      dokoResponses[.meanTemperature] = DokoCommandResponse(command: .tripEnding, response: .meanTemperature(meanTemperature))
    }
    return DokoResponsePacket(type: .tripEnding, responses: dokoResponses)
  }

  func tripUpdateResponsePacket(_ responsePacket: ObdResponsePacket) async -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
//      let odometer = responsePacket.odometer,
      let batteryStateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripUpdate, response: .error("arguments"))
      return DokoResponsePacket(type: .tripUpdate, responses: dokoResponses)
    }
    dokoResponses[.odometer] = DokoCommandResponse(command: .tripUpdate, response: .odometer(tripOdometer.odometer))
    dokoResponses[.distance] = DokoCommandResponse(command: .tripUpdate, response: .distance(tripOdometer.distance))
    //###
    dokoResponses[.position] = DokoCommandResponse(command: .tripUpdate, response: .position(position))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .tripUpdate, response: .batteryStateOfCharge(batteryStateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .tripUpdate, response: .batteryTemperature(batteryTemperature))

    if let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripUpdate, response: .batteryEnergy(hvBatteryEnergy))
    }
    if let latestWeather = await DokoWeatherManager.shared.latestWeather {
      dokoResponses[.weather] = DokoCommandResponse(command: .tripUpdate, response: .weather(latestWeather))
    }
    //###
    return DokoResponsePacket(type: .tripUpdate, responses: dokoResponses)
  }

  func tripEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryVoltage = responsePacket.batteryVoltage,
      let batteryCurrent = responsePacket.batteryCurrent
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripEnergy, response: .error("arguments"))
      return DokoResponsePacket(type: .tripEnergy, responses: dokoResponses)
    }

    if let batteryEnergy = hvBatteryEnergy.integrate(voltage: batteryVoltage, current: batteryCurrent, at: responsePacket.completedAt), let batteryPower = hvBatteryEnergy.power {
    dokoResponses[.batteryPower] = DokoCommandResponse(command: .tripEnergy, response: .batteryPower(batteryPower))
      dokoResponses[.batteryPower] = DokoCommandResponse(command: .tripEnergy, response: .batteryPower(batteryPower))
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripEnergy, response: .batteryEnergy(batteryEnergy))
    }
    return DokoResponsePacket(type: .tripEnergy, responses: dokoResponses)
  }

  func tripDataResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.batteryEnergyToEmpty,
      let stateOfCharge = responsePacket.batteryStateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripData, response: .error("arguments"))
      return DokoResponsePacket(type: .tripData, responses: dokoResponses)
    }
    tripOdometer.update(odometer: odometer)

    dokoResponses[.odometer] = DokoCommandResponse(command: .tripData, response: .odometer(tripOdometer.odometer))
    dokoResponses[.distance] = DokoCommandResponse(command: .tripData, response: .distance(tripOdometer.distance))
    dokoResponses[.batteryEnergyToEmpty] = DokoCommandResponse(command: .tripData, response: .batteryEnergyToEmpty(energyToEmpty))
    dokoResponses[.batteryStateOfCharge] = DokoCommandResponse(command: .tripData, response: .batteryStateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .tripData, response: .batteryTemperature(batteryTemperature))

    if let batteryDistanceToEmpty = responsePacket.batteryDistanceToEmpty {
      dokoResponses[.batteryDistanceToEmpty] = DokoCommandResponse(command: .tripData, response: .batteryDistanceToEmpty(batteryDistanceToEmpty))
    }
    if let hvBatteryEnergy = hvBatteryEnergy.energy {
      dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripData, response: .batteryEnergy(hvBatteryEnergy))
    }

    return DokoResponsePacket(type: .tripData, responses: dokoResponses)
  }
  
  func tripWeatherResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let weather = responsePacket.weather
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripWeather, response: .error("arguments"))
      return DokoResponsePacket(type: .tripWeather, responses: dokoResponses)
    }
    meanTemperatureSum += weather.temperature
    meanTemperatureCount += 1
    dokoResponses[.weather] = DokoCommandResponse(command: .tripWeather, response: .weather(weather))
    return DokoResponsePacket(type: .tripWeather, responses: dokoResponses)
  }
}
