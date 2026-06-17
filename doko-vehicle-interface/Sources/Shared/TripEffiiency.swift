import Foundation

public struct TripEfficiency: Sendable {
  public private(set) var efficiency: Double = 0

  public init() {}

  public mutating func reset() {
    efficiency = 0
  }

  @discardableResult
  public mutating func update() -> Double {
    return efficiency
  }
}
