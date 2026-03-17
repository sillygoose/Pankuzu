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
      case .ate(let enabled):
        commandResponse = .ate(enabled)
      case .ath(let enabled):
        commandResponse = .ath(enabled)
      case .atcaf(let enabled):
        commandResponse = .atcaf(enabled)
      case .ats(let enabled):
        commandResponse = .ats(enabled)
      case .stcsegr(let enabled):
        commandResponse = .stcsegr(enabled)
      case .atsp(let busProtocol):
        commandResponse = .atsp(busProtocol)
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
//###      DokoLogging.shared.postLoggingResponse(.error("\(command.description)(\(errorResult.description))"))
      let errorResponse: ObdResponse = .obdError(command.description, errorResult.description)
      return ObdCommandResponse(command: command, result: errorResult, response: errorResponse, rawCommand: rawCommand, rawResponse: response)
    }
  }
}
