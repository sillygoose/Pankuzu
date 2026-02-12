import Foundation

extension Charge {
  public enum ChargeError: Error, LocalizedError {
    case unknownVehicle
    case chargeWriteError, chargeUpdateError, chargeLocationError
    case chargeHistoryArgumentError, chargeWeatherArgumentError

    public var errorDescription: String {
      switch self {
      case .unknownVehicle:
        "Expected an active vehicle but was missing"

      case .chargeWriteError:
        "Error writing a Charge record"
      case .chargeUpdateError:
        "Error updating the Charge draft record"
      case .chargeLocationError:
        "Error processing the Charge location"

      case .chargeHistoryArgumentError:
        "Error extracting ChargeHistory arguments"
      case .chargeWeatherArgumentError:
        "Error extracting ChargeWeather arguments"
      }
    }
  }
}
