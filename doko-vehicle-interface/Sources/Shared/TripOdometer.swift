import Foundation

public struct TripOdometer: Sendable {
  private(set) var initialOdometer: Double = 0
  public private(set) var odometer: Double = 0
  public private(set) var distance: Double = 0

  public init() {}

  public mutating func setOdometer(with newOdometer: Double) {
    initialOdometer = newOdometer
    odometer = newOdometer
    distance = 0
  }

  @discardableResult
  public mutating func updateOdometer(with newOdometer: Double) -> Double {
    odometer = newOdometer
    distance += newOdometer - initialOdometer
    return distance
  }
}
