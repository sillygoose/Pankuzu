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
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature,
      let stateOfHealth = responsePacket.stateOfHealth
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripStarting, response: .error("arguments"))
      return DokoResponsePacket(type: .tripStarting, responses: dokoResponses)
    }
    batteryPower = 0.0
    batteryEnergy = 0.0
    lastEnergyUpdateTime = responsePacket.completedAt
    lastBatteryPower = nil
    meanTemperatureSum = 0.0
    meanTemperatureCount = 0
    dokoResponses[.nextState] = DokoCommandResponse(command: .tripStarting, response: .nextState(.tripInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: .tripStarting, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: .tripStarting, response: .odometer(odometer))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripStarting, response: .batteryEnergy(-batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .tripStarting, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .tripStarting, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .tripStarting, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .tripStarting, response: .batteryStateOfHealth(stateOfHealth))
    if let weather = responsePacket.weather {
      meanTemperatureSum += weather.temperature
      meanTemperatureCount += 1
      dokoResponses[.weather] = DokoCommandResponse(command: .tripStarting, response: .weather(weather))
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
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature,
      let stateOfHealth = responsePacket.stateOfHealth
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripEnding, response: .error("arguments"))
      return DokoResponsePacket(type: .tripEnding, responses: dokoResponses)
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .tripEnding, response: .nextState(.idle))
    dokoResponses[.position] = DokoCommandResponse(command: .tripEnding, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: .tripEnding, response: .odometer(odometer))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripEnding, response: .batteryEnergy(-batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .tripEnding, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .tripEnding, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .tripEnding, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .tripEnding, response: .batteryStateOfHealth(stateOfHealth))
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
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripUpdate, response: .error("arguments"))
      return DokoResponsePacket(type: .tripUpdate, responses: dokoResponses)
    }
    dokoResponses[.position] = DokoCommandResponse(command: .tripUpdate, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: .tripUpdate, response: .odometer(odometer))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripUpdate, response: .batteryEnergy(-batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .tripUpdate, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .tripUpdate, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .tripUpdate, response: .batteryTemperature(batteryTemperature))
    if let latestWeather = await DokoWeatherManager.shared.latestWeather {
      dokoResponses[.weather] = DokoCommandResponse(command: .tripUpdate, response: .weather(latestWeather))
    }
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
    batteryPower = batteryVoltage * batteryCurrent * 0.001
    if let lastTime = lastEnergyUpdateTime, let lastPower = lastBatteryPower {
      let deltaHours = responsePacket.completedAt.timeIntervalSince(lastTime) / 3600.0
      batteryEnergy += (lastPower + batteryPower) / 2.0 * deltaHours
    }
    lastEnergyUpdateTime = responsePacket.completedAt
    lastBatteryPower = batteryPower
    dokoResponses[.batteryPower] = DokoCommandResponse(command: .tripEnergy, response: .batteryPower(batteryPower))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripEnergy, response: .batteryEnergy(-batteryEnergy))
    return DokoResponsePacket(type: .tripEnergy, responses: dokoResponses)
  }

  func tripDataResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripData, response: .error("arguments"))
      return DokoResponsePacket(type: .tripData, responses: dokoResponses)
    }
    dokoResponses[.odometer] = DokoCommandResponse(command: .tripData, response: .odometer(odometer))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripData, response: .batteryEnergy(-batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .tripData, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .tripData, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .tripEnding, response: .batteryTemperature(batteryTemperature))
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
