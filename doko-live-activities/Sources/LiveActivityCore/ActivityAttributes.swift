import ActivityKit
import WeatherKit
import Foundation

public struct WindSock: Codable, Hashable, Sendable {
  public let course: Measurement<UnitAngle>
  public let temperature: Measurement<UnitTemperature>
  public let conditions: String
  public let windSpeed: Measurement<UnitSpeed>
  public let windDirection: Measurement<UnitAngle>
  public let windCompassDirection: String

  public init(
    course: Measurement<UnitAngle>,
    temperature: Measurement<UnitTemperature>,
    conditions: String,
    windSpeed: Measurement<UnitSpeed>,
    windDirection: Measurement<UnitAngle>,
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

public struct TripActivityAttributes: ActivityAttributes, Sendable {
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
    public let distance: Measurement<UnitLength>
    public let rangeConsumed: Measurement<UnitLength>?
    public let windSock: WindSock?

    public init(
      tripState: TripState,
      duration: Duration = .seconds(0),
      distance: Measurement<UnitLength> = .init(value: 0.0, unit: .kilometers),
      rangeConsumed: Measurement<UnitLength>? = nil,
      windSock: WindSock? = nil
    ) {
      self.tripState = tripState
      self.duration = duration
      self.distance = distance
      self.rangeConsumed = rangeConsumed
      self.windSock = windSock
    }
  }
}

public struct ChargeActivityAttributes: ActivityAttributes, Sendable {
  public let chargeID: UUID

  public init(chargeID: UUID = UUID()) {
    self.chargeID = chargeID
  }

  public struct ContentState: Codable, Hashable, Sendable {
    public enum ChargeState: Codable, Hashable, Sendable {
      case starting, active, ended

      public var description: String {
        switch self {
        case .starting: return "Starting charge"
        case .active: return "Charge in progress"
        case .ended: return "Charge ended"
        }
      }
    }

    public let chargeState: ChargeState
    public let duration: Duration
    public let stateOfCharge: Measurement<UnitPercent>
    public let rangeAdded: Measurement<UnitLength>?
    public let measuredPower: Measurement<UnitPower>?

    public init(
      chargeState: ChargeState,
      duration: Duration = .seconds(0),
      stateOfCharge: Measurement<UnitPercent> = .init(value: 0.0, unit: .percent),
      rangeAdded: Measurement<UnitLength>? = nil,
      measuredPower: Measurement<UnitPower>? = nil,
    ) {
      self.chargeState = chargeState
      self.duration = duration
      self.stateOfCharge = stateOfCharge
      self.rangeAdded = rangeAdded
      self.measuredPower = measuredPower
    }
  }
}
