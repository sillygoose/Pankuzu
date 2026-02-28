import OSLog

import DokoLogging
import ObdLinkCore

extension UndeterminedVehicle {
  public func vehicleObdCommandResponse(_ command: ObdCommand, _ response: String, rawCommand: String) async -> ObdCommandResponse {
    self.logger.info("\(timestamp()) UV.parsedResponse(\(command.description), \(response))")
    let result: ObdResult = .ok
    do {
      var commandResponse: ObdResponse
      switch command {
      case .atz:
        commandResponse = .atz(response)
      case .ate0:
        commandResponse = .ate0
      case .ath0:
        commandResponse = .ath0
      case .atcaf1:
        commandResponse = .atcaf1
      case .ats0:
        commandResponse = .ats0
      case .stcsegr1:
        commandResponse = .stcsegr1
      case .atsp0:
        commandResponse = .atsp0
      case .stprs:
        commandResponse = .stprs(response)
        
      case .vin:
        let vin = try parseVin(response)
        commandResponse = .vin(vin)

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
