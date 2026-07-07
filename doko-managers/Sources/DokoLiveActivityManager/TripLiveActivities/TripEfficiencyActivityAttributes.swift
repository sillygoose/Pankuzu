import ActivityKit
import WeatherKit
import Foundation

public struct TripEfficiencyActivityAttributes: ActivityAttributes, Sendable {
  public let tripID: UUID

  public init(tripID: UUID = UUID()) {
    self.tripID = tripID
  }

  public struct ContentState: Codable, Hashable, Sendable {
    public enum TripState: Codable, Hashable, Sendable {
      case starting, active, ended

      public var description: String {
        switch self {
        case .starting: return "Starting trip"
        case .active: return "Trip in progress"
        case .ended: return "Trip ended"
        }
      }
    }

    public let tripState: TripState
    public let duration: Duration
    public let distance: Double
    public let energy: Double?
    public let efficiency: Double?
    public let elevation: Double?
    public let rangeConsumed: Double?
    public let windSock: WindSock?

    public init(
      tripState: TripState,
      duration: Duration = .seconds(0),
      distance: Double = 0.0,
      energy: Double? = nil,
      efficiency: Double? = nil,
      elevation: Double? = nil,
      rangeConsumed: Double? = nil,
      windSock: WindSock? = nil
    ) {
      self.tripState = tripState
      self.duration = duration
      self.distance = distance
      self.energy = energy
      self.efficiency = efficiency
      self.elevation = elevation
      self.rangeConsumed = rangeConsumed
      self.windSock = windSock
    }
  }
}
