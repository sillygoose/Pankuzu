import Foundation

import DokoTypes
import ObdLinkCore

extension VwElectrics {
  public enum ParsedResponseError: Error, LocalizedError {
    case unexpectedCommand(ObdCommand, String)
    case unexpectedState(VehicleState)
    case locationUnavailable
    case weatherUnavailable

    public var errorDescription: String {
      switch self {
      case .unexpectedCommand(let command, let response):
        "An unexpected command was received: \(command.description)(\(response))"
      case .unexpectedState(let state):
        "An unexpected state was scheduled: \(state.description)"
      case .locationUnavailable:
        "Request for location failed"
      case .weatherUnavailable:
        "Request for weather failed"
      }
    }
  }
}
