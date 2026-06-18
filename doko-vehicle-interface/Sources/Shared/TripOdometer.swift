import Foundation

public struct TripOdometer: Sendable {
  private(set) var initialOdometer: Double = 0
  public private(set) var odometer: Double = 0
  public private(set) var distance: Double = 0

  public init() {}

  @discardableResult
  public mutating func setOdometer(with newOdometer: Double) -> Double {
    initialOdometer = newOdometer
    odometer = newOdometer
    distance = 0
    return distance
  }

  @discardableResult
  public mutating func updateOdometer(with newOdometer: Double) -> Double {
    odometer = newOdometer
    distance = newOdometer - initialOdometer
    return distance
  }
}
