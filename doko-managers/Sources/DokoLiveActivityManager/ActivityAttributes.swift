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
    public let distance: Double
    public let energy: Double?
    public let elevation: Double?
    public let rangeConsumed: Double?
    public let windSock: WindSock?

    public init(
      tripState: TripState,
      duration: Duration = .seconds(0),
      distance: Double = 0.0,
      energy: Double? = nil,
      elevation: Double? = nil,
      rangeConsumed: Double? = nil,
      windSock: WindSock? = nil
    ) {
      self.tripState = tripState
      self.duration = duration
      self.distance = distance
      self.energy = energy
      self.elevation = elevation
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
    public let stateOfCharge: Double?
    public let energy: Double?
    public let rangeAdded: Double?
    public let measuredPower: Double?
    public let batteryVoltage: Double?
    public let batteryCurrent: Double?
    public let batteryTemperature: Double?
    public let couplerTemperature: Double?

    public init(
      chargeState: ChargeState,
      duration: Duration = .seconds(0),
      stateOfCharge: Double? = nil,
      energy: Double? = nil,
      rangeAdded: Double? = nil,
      measuredPower: Double? = nil,
      batteryVoltage: Double? = nil,
      batteryCurrent: Double? = nil,
      batteryTemperature: Double? = nil,
      couplerTemperature: Double? = nil,
    ) {
      self.chargeState = chargeState
      self.duration = duration
      self.stateOfCharge = stateOfCharge
      self.energy = energy
      self.rangeAdded = rangeAdded
      self.measuredPower = measuredPower
      self.batteryVoltage = batteryVoltage
      self.batteryCurrent = batteryCurrent
      self.batteryTemperature = batteryTemperature
      self.couplerTemperature = couplerTemperature
    }
  }
}
