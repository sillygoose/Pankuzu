import Foundation

extension Trip {
  public enum TripError: Error, LocalizedError {
    case unknownVehicle
    case tripWriteError, tripUpdateError, tripLocationError
    case tripPositionArgumentError, tripElevationrgumentError, tripDataArgumentError, tripWeatherArgumentError

    public var errorDescription: String {
      switch self {
      case .unknownVehicle:
        "Expected an active vehicle but was missing"

      case .tripWriteError:
        "Error writing a Trip record"
      case .tripUpdateError:
        "Error updating the Trip draft record"
      case .tripLocationError:
        "Error processing Trip location"
        
      case .tripPositionArgumentError:
        "Error extracting TripPosition arguments"
      case .tripElevationrgumentError:
        "Error extracting TripElevation arguments"
      case .tripDataArgumentError:
        "Error extracting TripData arguments"
      case .tripWeatherArgumentError:
        "Error extracting TripWeather arguments"
      }
    }
  }
}
