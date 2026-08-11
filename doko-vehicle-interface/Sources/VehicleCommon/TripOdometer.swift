import Foundation

import DokoTypes

public struct TripOdometer: Sendable {
  public var odometer: Double { (rawOdometer * 10).rounded() / 10 }
  public var distance: Double { (rawDistance * 10).rounded() / 10 }
  
  private(set) var initialOdometer: Double = 0
  private var rawOdometer: Double = 0
  private var rawDistance: Double = 0
  
  public init() {}
  
  @discardableResult
  public mutating func setOdometer(with newOdometer: Double) -> Double {
    initialOdometer = newOdometer
    rawOdometer = newOdometer
    rawDistance = 0
    return distance
  }
  
  @discardableResult
  public mutating func resetTripOdometer(with newOdometer: Double, and newPosition: DokoPosition) -> Double {
    initialOdometer = newOdometer
    rawOdometer = newOdometer
    rawDistance = 0
    return distance
  }
  
  @discardableResult
  public mutating func updateOdometer(with newOdometer: Double) -> Double {
    rawOdometer = newOdometer
    rawDistance = newOdometer - initialOdometer
    return distance
  }
  
  @discardableResult
  public mutating func updateTripOdometer(with newOdometer: Double, and newPosition: DokoPosition) -> Double {
    rawOdometer = newOdometer
    rawDistance = newOdometer - initialOdometer
    return distance
  }
}
