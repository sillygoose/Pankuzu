import OSLog

import DokoTypes
import ObdLinkCore

extension FordElectrics {
  func acChargeStartingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let position = responsePacket.position,
      let odometer = responsePacket.odometer,
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let stateOfHealth = responsePacket.stateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.acChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeStarting, response: .error("agruments"))
      return DokoResponsePacket(type: .acChargeStarting, responses: dokoResponses)
    }
    batteryPower = 0.0
    batteryEnergy = 0.0
    lastEnergyUpdateTime = responsePacket.completedAt
    lastBatteryPower = nil
    dokoResponses[.nextState] = DokoCommandResponse(command: .acChargeStarting, response: .nextState(.acChargeInProgress))
    dokoResponses[.position] = DokoCommandResponse(command: .acChargeStarting, response: .position(position))
    dokoResponses[.odometer] = DokoCommandResponse(command: .acChargeStarting, response: .odometer(odometer))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeStarting, response: .batteryEnergy(batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .acChargeStarting, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .acChargeStarting, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .acChargeStarting, response: .batteryStateOfHealth(stateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .acChargeStarting, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .acChargeStarting, response: .couplerTemperature(couplerTemperature))
    if let weather = responsePacket.weather {
      dokoResponses[.weather] = DokoCommandResponse(command: .acChargeStarting, response: .weather(weather))
    }
    return DokoResponsePacket(type: .acChargeStarting, responses: dokoResponses)
  }
  
  func acChargeInProgressResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let acChargerStatus = responsePacket.acChargerStatus
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeInProgress, response: .error("agruments"))
      return DokoResponsePacket(type: .acChargeInProgress, responses: dokoResponses)
    }
    let nextState: VehicleState = acChargerStatus ? .acChargeInProgress: .acChargeEnding
    dokoResponses[.nextState] = DokoCommandResponse(command: .acChargeInProgress, response: .nextState(nextState))
    return DokoResponsePacket(type: .acChargeInProgress, responses: dokoResponses)
  }

  func acChargeUpdateResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let stateOfHealth = responsePacket.stateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.acChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeUpdate, response: .error("agruments"))
      return DokoResponsePacket(type: .acChargeUpdate, responses: dokoResponses)
    }
    dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryPower(batteryPower))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryEnergy(batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .acChargeUpdate, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .acChargeUpdate, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryStateOfHealth(stateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .acChargeUpdate, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .acChargeUpdate, response: .couplerTemperature(couplerTemperature))
    return DokoResponsePacket(type: .acChargeUpdate, responses: dokoResponses)
  }

  func acChargeEndingResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let stateOfHealth = responsePacket.stateOfHealth,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.acChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeEnding, response: .error("agruments"))
      return DokoResponsePacket(type: .acChargeEnding, responses: dokoResponses)
    }
    dokoResponses[.nextState] = DokoCommandResponse(command: .acChargeEnding, response: .nextState(.idle))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeEnding, response: .batteryEnergy(batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .acChargeStarting, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .acChargeEnding, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryStateOfHealth] = DokoCommandResponse(command: .acChargeEnding, response: .batteryStateOfHealth(stateOfHealth))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .acChargeEnding, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .acChargeEnding, response: .couplerTemperature(couplerTemperature))
    return DokoResponsePacket(type: .acChargeEnding, responses: dokoResponses)
  }

  func acChargeEnergyResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let batteryVoltage = responsePacket.batteryVoltage,
      let batteryCurrent = responsePacket.batteryCurrent
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeEnergy, response: .error("agruments"))
      return DokoResponsePacket(type: .acChargeEnergy, responses: dokoResponses)
    }
    batteryPower = batteryVoltage * batteryCurrent * 0.001
    if let lastTime = lastEnergyUpdateTime, let lastPower = lastBatteryPower {
      let deltaHours = responsePacket.completedAt.timeIntervalSince(lastTime) / 3600.0
      batteryEnergy += (lastPower + batteryPower) / 2.0 * deltaHours
    }
    lastEnergyUpdateTime = responsePacket.completedAt
    lastBatteryPower = batteryPower
    dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeEnergy, response: .batteryPower(batteryPower))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeEnergy, response: .batteryEnergy(batteryEnergy))
    return DokoResponsePacket(type: .acChargeEnergy, responses: dokoResponses)
  }

  func acChargeHistoryResponsePacket(_ responsePacket: ObdResponsePacket) -> DokoResponsePacket {
    var dokoResponses: DokoResponseDictionary = [:]
    guard
      let energyToEmpty = responsePacket.energyToEmpty,
      let stateOfCharge = responsePacket.stateOfCharge,
      let batteryTemperature = responsePacket.batteryTemperature,
      let couplerTemperature = responsePacket.acChargerCouplerTemperature
    else {
      dokoResponses[.error] = DokoCommandResponse(command: .acChargeHistory, response: .error("agruments"))
      return DokoResponsePacket(type: .acChargeHistory, responses: dokoResponses)
    }
    dokoResponses[.batteryPower] = DokoCommandResponse(command: .acChargeHistory, response: .batteryPower(batteryPower))
    dokoResponses[.batteryEnergy] = DokoCommandResponse(command: .acChargeHistory, response: .batteryEnergy(batteryEnergy))
    dokoResponses[.energyToEmpty] = DokoCommandResponse(command: .acChargeHistory, response: .energyToEmpty(energyToEmpty))
    dokoResponses[.stateOfCharge] = DokoCommandResponse(command: .acChargeHistory, response: .stateOfCharge(stateOfCharge))
    dokoResponses[.batteryTemperature] = DokoCommandResponse(command: .acChargeHistory, response: .batteryTemperature(batteryTemperature))
    dokoResponses[.couplerTemperature] = DokoCommandResponse(command: .acChargeHistory, response: .couplerTemperature(couplerTemperature))
    return DokoResponsePacket(type: .acChargeHistory, responses: dokoResponses)
  }
}
