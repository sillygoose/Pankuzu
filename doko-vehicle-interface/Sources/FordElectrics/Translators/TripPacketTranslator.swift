import OSLog

import DokoTypes
import ObdLinkCore

extension FordElectrics {
  func tripStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let weather = responsePacket.weather,
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature,
      let stateOfHealth = responsePacket.stateOfHealth
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripStarting, response: .error("agruments"))
      return DokoResponsePacket(type: .tripStarting, responses: dokoResponses)
    }
    batteryPower = 0.0
    batteryEnergy = 0.0
    lastEnergyUpdateTime = responsePacket.completedAt
    lastBatteryPower = nil
    dokoResponses[.nextState] = DokoCommandResponse(command: .tripStarting, response: .nextState(.tripInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: .tripStarting, response: .position(position))
    dokoResponses[.weather] = DokoCommandResponse(command: .tripStarting, response: .weather(weather))
    dokoResponses[.odometer] = DokoCommandResponse(command: .tripStarting, response: .odometer(odometer))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripStarting, response: .batteryEnergy(-batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .tripStarting, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .tripStarting, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .tripStarting, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .tripStarting, response: .batteryStateOfHealth(stateOfHealth))
    return DokoResponsePacket(type: .tripStarting, responses: dokoResponses)
  }
  
  func tripInProgressResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let gearSelected = responsePacket.gearSelected
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripInProgress, response: .error("agruments"))
      return DokoResponsePacket(type: .tripInProgress, responses: dokoResponses)
    }
    let nextState: VehicleState = gearSelected ? .tripInProgress: .tripEnding
    dokoResponses[.nextState] = DokoCommandResponse(command: .tripInProgress, response: .nextState(nextState))
    return DokoResponsePacket(type: .tripInProgress, responses: dokoResponses)
  }
  
  func tripEndingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let weather = responsePacket.weather,
      let meanTemperature = responsePacket.meanTemperature,
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature,
      let stateOfHealth = responsePacket.stateOfHealth
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripEnding, response: .error("agruments"))
      return DokoResponsePacket(type: .tripEnding, responses: dokoResponses)
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .tripEnding, response: .nextState(.idle))
    dokoResponses[.position] = DokoCommandResponse(command: .tripEnding, response: .position(position))
    dokoResponses[.weather] = DokoCommandResponse(command: .tripEnding, response: .weather(weather))
    dokoResponses[.odometer] = DokoCommandResponse(command: .tripEnding, response: .odometer(odometer))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripEnding, response: .batteryEnergy(-batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .tripEnding, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .tripEnding, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .tripEnding, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .tripEnding, response: .batteryStateOfHealth(stateOfHealth))
    dokoResponses[.meanTemperature] = DokoCommandResponse(command: .tripEnding, response: .meanTemperature(meanTemperature))
    return DokoResponsePacket(type: .tripEnding, responses: dokoResponses)
  }

  func tripUpdateResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripUpdate, response: .error("agruments"))
      return DokoResponsePacket(type: .tripUpdate, responses: dokoResponses)
    }
    dokoResponses[.position] = DokoCommandResponse(command: .tripUpdate, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: .tripUpdate, response: .odometer(odometer))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripUpdate, response: .batteryEnergy(-batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .tripUpdate, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .tripUpdate, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .tripUpdate, response: .batteryTemperature(batteryTemperature))
    return DokoResponsePacket(type: .tripUpdate, responses: dokoResponses)
  }

  func tripEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryVoltage = responsePacket.batteryVoltage,
      let batteryCurrent = responsePacket.batteryCurrent
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripEnergy, response: .error("agruments"))
      return DokoResponsePacket(type: .tripEnergy, responses: dokoResponses)
    }
    batteryPower = batteryVoltage * batteryCurrent * 0.001
    if let lastTime = lastEnergyUpdateTime, let lastPower = lastBatteryPower {
      let deltaHours = responsePacket.completedAt.timeIntervalSince(lastTime) / 3600.0
      // Trapezoid integration: average of last and current power
      batteryEnergy += (lastPower + batteryPower) / 2.0 * deltaHours
    }
    lastEnergyUpdateTime = responsePacket.completedAt
    lastBatteryPower = batteryPower
    dokoResponses[.batteryPower] = DokoCommandResponse(command: .tripEnergy, response: .batteryPower(batteryPower))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .tripEnergy, response: .batteryEnergy(-batteryEnergy))
    return DokoResponsePacket(type: .tripEnergy, responses: dokoResponses)
  }

//  func tripPositionResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
//    var dokoResponses: DokoResponseDictionary = [:]
//    guard
//      let position = responsePacket.position
//    else {
//      return DokoResponsePacket(type: .tripPosition, responses: dokoResponses)
//    }
//    dokoResponses[.position] = DokoCommandResponse(command: .tripPosition, response: .position(position))
//    return DokoResponsePacket(type: .tripPosition, responses: dokoResponses)
//  }

  func tripDataResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .tripData, response: .error("agruments"))
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
      dokoResponses[.error] = DokoCommandResponse(command: .tripWeather, response: .error("agruments"))
      return DokoResponsePacket(type: .tripWeather, responses: dokoResponses)
    }
    dokoResponses[.weather] = DokoCommandResponse(command: .tripWeather, response: .weather(weather))
    return DokoResponsePacket(type: .tripWeather, responses: dokoResponses)
  }
}
