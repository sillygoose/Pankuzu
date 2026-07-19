import ActivityKit
import WeatherKit
import Foundation

public struct WindSock: Codable, Hashable, Sendable {
  public let course: Double
  public let temperature: Double
  public let conditions: String
  public let windSpeed: Double
  public let windDirection: Double
  public let windCompassDirection: String

  public init(
    course: Double,
    temperature: Double,
    conditions: String,
    windSpeed: Double,
    windDirection: Double,
    windCompassDirection: String
  ) {
    self.course = course
    self.temperature = temperature
    self.conditions = conditions
    self.windSpeed = windSpeed
    self.windDirection = windDirection
    self.windCompassDirection = windCompassDirection
  }
}

public struct TripOverviewActivityAttributes: ActivityAttributes, Sendable {
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
    public let efficiencyMovingAverage: [EfficiencyPoint]
    
    public init(
      tripState: TripState,
      duration: Duration = .seconds(0),
      distance: Double = 0.0,
      energy: Double? = nil,
      efficiency: Double? = nil,
      elevation: Double? = nil,
      rangeConsumed: Double? = nil,
      windSock: WindSock? = nil,
      efficiencyMovingAverage: [EfficiencyPoint] = []
    ) {
      self.tripState = tripState
      self.duration = duration
      self.distance = distance
      self.energy = energy
      self.efficiency = efficiency
      self.elevation = elevation
      self.rangeConsumed = rangeConsumed
      self.windSock = windSock
      self.efficiencyMovingAverage = efficiencyMovingAverage
    }
  }
}
