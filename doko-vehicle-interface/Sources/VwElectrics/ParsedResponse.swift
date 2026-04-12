import OSLog

import DokoLogging
import DokoTypes
import ObdLinkCore
import DokoWeatherManager
import CoreLocationManager

extension VwElectrics {
  public func vehicleObdCommandResponse(_ command: ObdCommand, _ response: String, rawCommand: String) async -> ObdCommandResponse {
    let result: ObdResult = .ok
    do {
      var commandResponse: ObdResponse
      switch command {
//      case .ath(let enabled):
//        commandResponse = .ath(enabled)
//      case .stpx(_, _):
//        commandResponse = .stpx(response)
      case .atz:
        commandResponse = .atz(response)
      case .ate(let enabled):
        commandResponse = .ate(enabled)
      case .ath(let enabled):
        commandResponse = .ath(enabled)
      case .atcfc(let enabled):
        commandResponse = .atcfc(enabled)
      case .atcaf(let enabled):
        commandResponse = .atcaf(enabled)
      case .ats(let enabled):
        commandResponse = .ats(enabled)
      case .atsp(let canProtocol):
        commandResponse = .atsp(canProtocol)
      case .atsh(let header):
        commandResponse = .atsh(header)
      case .atcp(let header):
        commandResponse = .atcp(header)
      case .atcf(let pattern):
        commandResponse = .atcf(pattern)
      case .atcra(let pattern):
        commandResponse = .atcra(pattern)
      case .atcm(let mask):
        commandResponse = .atcm(mask)
      case .stcsegr(let enabled):
        commandResponse = .stcsegr(enabled)

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
