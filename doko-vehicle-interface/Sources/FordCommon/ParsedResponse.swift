import OSLog

import DokoTypes
import ObdLinkCore
import DokoWeatherManager
import CoreLocationManager

import VehicleCommon

extension FordTranslating {
  public func vehicleObdCommandResponse(_ command: ObdCommand, _ response: String, rawCommand: String) async -> ObdCommandResponse {
    let result: ObdResult = .ok
    do {
      var commandResponse: ObdResponse
      switch command {
      case .stp(let canProtocol):
        try parseSTP(response)
        commandResponse = .stp(canProtocol)
      case .stpbr(let baudRate):
        try parseSTPBR(response)
        commandResponse = .stpbr(baudRate)
      case .stpo:
        try parseSTPO(response)
        commandResponse = .stpo(response)

      case .position:
        guard let position = await CoreLocationManager.shared.currentPosition else {
          throw ParsedResponseError.locationUnavailable
        }
        commandResponse = .position(DokoPosition(position: position))

      case .weather:
        guard let position = await CoreLocationManager.shared.currentPosition else {
          throw ParsedResponseError.locationUnavailable
        }
        guard
          let currentWeather = await DokoWeatherManager.shared.currentWeather(for: position)
        else {
          throw ParsedResponseError.weatherUnavailable
        }
        commandResponse = .weather(currentWeather)

      case .odometer:
        let odometer = try parseVehicleOdometer(response)
        commandResponse = .odometer(odometer)
      case .speed:
        let speed = try parseVehicleSpeed(response)
        commandResponse = .speed(speed)
      case .gearSelected:
        let gearSelected = try parseGearSelected(response)
        commandResponse = .gearSelected(gearSelected)

      case .batteryEnergyToEmpty:
        let ete = try parseHvbEnergyToEmpty(response)
        commandResponse = .batteryEnergyToEmpty(ete)
      case .batteryStateOfCharge:
        let soc = try parseHvbStateOfCharge(response)
        commandResponse = .batteryStateOfCharge(soc)
      case .batteryStateOfHealth:
        let soh = try parseHvbStateOfHealth(response)
        commandResponse = .batteryStateOfHealth(soh)
      case .batteryTemperature:
        let temperature = try parseHvbTemperature(response)
        commandResponse = .batteryTemperature(temperature)

      case .batteryVoltage:
        let voltage = try parseHvbVoltage(response)
        commandResponse = .batteryVoltage(voltage)
      case .batteryCurrent:
        let current = try parseHvbCurrent(response)
        commandResponse = .batteryCurrent(current)
      case .batteryChargeVoltageRequested:
        let voltage = try parseHvbChargeVoltageRequested(response)
        commandResponse = .batteryChargeVoltageRequested(voltage)
      case .batteryChargeCurrentRequested:
        let current = try parseHvbChargeCurrentRequested(response)
        commandResponse = .batteryChargeCurrentRequested(current)

      case .chargerInputVoltage:
        let voltage = try parseAcChargerInputVoltage(response)
        commandResponse = .chargerInputVoltage(voltage)
      case .chargerInputCurrent:
        let current = try parseAcChargerInputCurrent(response)
        commandResponse = .chargerInputCurrent(current)
      case .chargerOutputVoltage:
        let voltage = try parseChargerOutputVoltage(response)
        commandResponse = .chargerOutputVoltage(voltage)
      case .chargerOutputCurrent:
        let current = try parseChargerOutputCurrent(response)
        commandResponse = .chargerOutputCurrent(current)

      case .acChargerStatus:
        let status = try parseAcChargerStatus(response)
        commandResponse = .acChargerStatus(status)
      case .acChargerCouplerTemperature:
        let temperature = try parseAcChargerCouplerTemperature(response)
        commandResponse = .acChargerCouplerTemperature(temperature)

      case .dcChargerStatus:
        let status = try parseDcChargerStatus(response)
        commandResponse = .dcChargerStatus(status)
      case .dcChargerCouplerTemperature1:
        let temperature = try parseDcChargerCouplerTemperature1(response)
        commandResponse = .dcChargerCouplerTemperature1(temperature)
      case .dcChargerCouplerTemperature3:
        let temperature = try parseDcChargerCouplerTemperature3(response)
        commandResponse = .dcChargerCouplerTemperature3(temperature)

      default:
        throw ParsedResponseError.unexpectedCommand(command, response)
      }
      return ObdCommandResponse(command: command, result: result, response: commandResponse, rawCommand: rawCommand, rawResponse: response)
    } catch {
      let errorResult = ObdResult.getObdError(errorString: response)
      let errorResponse: ObdResponse = .obdError(command.description, errorResult.description)
      return ObdCommandResponse(command: command, result: errorResult, response: errorResponse, rawCommand: rawCommand, rawResponse: response)
    }
  }
}
