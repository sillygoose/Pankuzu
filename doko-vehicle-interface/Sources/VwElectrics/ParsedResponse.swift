import OSLog

import DokoLogging
import DokoTypes
import ObdLinkCore
import DokoWeatherManager
import CoreLocationManager

extension VwElectrics {
  public func vehicleObdCommandResponse(_ command: ObdCommand, _ response: String, rawCommand: String) async -> ObdCommandResponse {
    //self.logger.info("\(timestamp()) VWE.parsedResponse(\(command.description), \(response))")
    let result: ObdResult = .ok
    do {
      var commandResponse: ObdResponse
      switch command {
      case .extendedDiagnosticSession:
        commandResponse = .extendedDiagnosticSession
      case .testerPresent:
        commandResponse = .testerPresent

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

      case .meanTemperature:
        guard
          let meanTemperature = await DokoWeatherManager.shared.meanTemperature
        else {
          throw ParsedResponseError.meanTemperatureUnavailable
        }
        commandResponse = .meanTemperature(meanTemperature)

      case .gearSelected:
        let gearSelected = try parseGearSelected(response)
        commandResponse = .gearSelected(gearSelected)
      case .odometer:
        let odometer = try parseOdometer(response)
        commandResponse = .odometer(odometer)

      case .stateOfCharge:
        let soc = try parseHvbStateOfCharge(response)
        commandResponse = .stateOfCharge(soc)
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
      case .dcChargerStatus:
        let status = try parseDcChargerStatus(response)
        commandResponse = .dcChargerStatus(status)

      default:
        throw ParsedResponseError.unexpectedCommand(command, response)
      }
      return ObdCommandResponse(command: command, result: result, response: commandResponse, rawCommand: rawCommand, rawResponse: response)
    } catch {
      let errorResult = ObdResult.getObdError(errorString: response)
      DokoLogging.shared.postLoggingResponse(.error("VWE.vehicleObdCommandResponse: \(command.description)(\(errorResult.description))"))
      let errorResponse: ObdResponse = .obdError(command.description, errorResult.description)
      return ObdCommandResponse(command: command, result: errorResult, response: errorResponse, rawCommand: rawCommand, rawResponse: response)
    }
  }
}
