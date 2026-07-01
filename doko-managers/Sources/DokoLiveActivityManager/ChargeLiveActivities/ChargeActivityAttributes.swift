import ActivityKit
import WeatherKit
import Foundation

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
