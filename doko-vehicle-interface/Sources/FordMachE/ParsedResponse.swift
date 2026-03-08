import OSLog

import DokoLogging
import DokoTypes
import ObdLinkCore
import DokoWeatherManager
import CoreLocationManager

extension FordMachE {
  public func vehicleObdCommandResponse(_ command: ObdCommand, _ response: String, rawCommand: String) async -> ObdCommandResponse {
    let result: ObdResult = .ok
    do {
      var commandResponse: ObdResponse
      switch command {
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

      case .odometer:
        let odometer = try parseOdometer(response)
        commandResponse = .odometer(odometer)
      case .gearSelected:
        let gearSelected = try parseGearSelected(response)
        commandResponse = .gearSelected(gearSelected)

      case .energyToEmpty:
        let ete = try parseHvbEnergyToEmpty(response)
        commandResponse = .energyToEmpty(ete)
      case .stateOfCharge:
        let soc = try parseHvbStateOfCharge(response)
        commandResponse = .stateOfCharge(soc)
      case .stateOfHealth:
        let soh = try parseHvbStateOfHealth(response)
        commandResponse = .stateOfHealth(soh)
      case .batteryTemperature:
        let temperature = try parseHvbTemperature(response)
        commandResponse = .batteryTemperature(temperature)
      case .batteryVoltage:
        let voltage = try parseHvbVoltage(response)
        commandResponse = .batteryVoltage(voltage)
      case .batteryCurrent:
        let current = try parseHvbCurrent(response)
        commandResponse = .batteryCurrent(current)

      case .acChargerStatus:
        let status = try parseAcChargerStatus(response)
        commandResponse = .acChargerStatus(status)
      case .acChargerCouplerTemperature:
        let temperature = try parseAcChargerCouplerTemperature(response)
        commandResponse = .acChargerCouplerTemperature(temperature)

      case .dcChargerStatus:
        let status = try parseDcChargerStatus(response)
        commandResponse = .dcChargerStatus(status)
      case .dcChargerCouplerTemperature:
        let temperature = try parseDcChargerCouplerTemperature(response)
        commandResponse = .dcChargerCouplerTemperature(temperature)

      default:
        throw ParsedResponseError.unexpectedCommand(command, response)
      }
      return ObdCommandResponse(command: command, result: result, response: commandResponse, rawCommand: rawCommand, rawResponse: response)
    } catch {
      let errorResult = ObdResult.getObdError(errorString: response)
      DokoLogging.shared.postLoggingResponse(.error("\(command.description)(\(errorResult.description))"))
      let errorResponse: ObdResponse = .obdError(command.description, errorResult.description)
      return ObdCommandResponse(command: command, result: errorResult, response: errorResponse, rawCommand: rawCommand, rawResponse: response)
    }
  }
}
