import OSLog

import DokoLogging
import DokoTypes
import ObdLinkCore
import DokoWeatherManager
import CoreLocationManager

import Shared

extension VwElectrics {
  public func vehicleObdCommandResponse(_ command: ObdCommand, _ response: String, rawCommand: String) async -> ObdCommandResponse {
    let result: ObdResult = .ok
    do {
      var commandResponse: ObdResponse
      switch command {
      case .atcra(let pattern):
        try parseATCRA(response)
        commandResponse = .atcra(pattern)
      case .atfcsh(let header):
        try parseATFCSH(response)
        commandResponse = .atfcsh(header)
      case .atfcsd(let data):
        try parseATFCSD(response)
        commandResponse = .atfcsd(data)
      case .atfcsm(let mode):
        try parseATFCSM(response)
        commandResponse = .atfcsm(mode)

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
        guard let position = await CoreLocationManager.shared.currentLocation else {
          throw ParsedResponseError.locationUnavailable
        }
        commandResponse = .position(DokoPosition(position: position))

      case .weather:
        guard let position = await CoreLocationManager.shared.currentLocation else {
          throw ParsedResponseError.locationUnavailable
        }
        guard
          let currentWeather = await DokoWeatherManager.shared.currentWeather(for: position)
        else {
          throw ParsedResponseError.weatherUnavailable
        }
        commandResponse = .weather(currentWeather)

      case .gearSelected:
        let gearSelected = try parseGearSelected(response)
        commandResponse = .gearSelected(gearSelected)
      case .odometer:
        let odometer = try parseOdometer(response)
        commandResponse = .odometer(odometer)
      case .speed:
        let speed = try parseSpeed(response)
        commandResponse = .speed(speed)

      case .batteryStateOfCharge:
        let soc = try parseHvbStateOfCharge(response)
        commandResponse = .batteryStateOfCharge(soc)
      case .batteryCurrentCapacity:
        let batteryCurrentCapacity = try parseHvbCurrentCapacity(response)
        commandResponse = .batteryCurrentCapacity(batteryCurrentCapacity)
      case .batteryOriginalCapacity:
        let batteryOriginalCapacity = try parseHvbOriginalCapacity(response)
        commandResponse = .batteryOriginalCapacity(batteryOriginalCapacity)
      case .batteryTemperature:
        let temperature = try parseHvbTemperature(response)
        commandResponse = .batteryTemperature(temperature)
      case .batteryVoltage:
        let voltage = try parseHvbVoltage(response)
        commandResponse = .batteryVoltage(voltage)
      case .batteryCurrent:
        let current = try parseHvbCurrent(response)
        commandResponse = .batteryCurrent(current)
      case .batteryDistanceToEmpty:
        let dte = try parseHvbDistanceToEmpty(response)
        commandResponse = .batteryDistanceToEmpty(dte)

      case .acChargerStatus:
        let status = try parseAcChargerStatus(response)
        commandResponse = .acChargerStatus(status)
      case .dcChargerStatus:
        let status = try parseDcChargerStatus(response)
        commandResponse = .dcChargerStatus(status)

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
