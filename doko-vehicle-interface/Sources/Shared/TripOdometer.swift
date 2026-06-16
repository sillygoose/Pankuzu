import Foundation

public struct TripOdometer: Sendable {
  public private(set) var initialOdometer: Double = 0
  public private(set) var odometer: Double = 0
  public private(set) var distance: Double = 0

  public init() {}

  public mutating func reset(odometer newOdometer: Double) {
    initialOdometer = newOdometer
    odometer = newOdometer
    distance = 0
  }

  @discardableResult
  public mutating func update(odometer newOdometer: Double) -> Double {
    odometer = newOdometer
    distance += newOdometer - initialOdometer
    return distance
  }
}
