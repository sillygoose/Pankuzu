
import Foundation

import ObdLinkCore

extension UndeterminedVehicle {
  public enum ParsedResponseError: Error, LocalizedError {
    case unexpectedCommand(ObdCommand, String)

    public var errorDescription: String {
      switch self {
      case .unexpectedCommand(let command, let resppnse):
        "An unexpected command was received: \(command.description)(\(resppnse))"
      }
    }
  }
}
