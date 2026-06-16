import Foundation

public struct MeanTemperature: Sendable {
  public private(set) var total: Double = 0
  public private(set) var samples: Int = 0
  public private(set) var mean: Double?

  public init() {}

  public mutating func reset() {
    total = 0
    samples = 0
    mean = nil
  }

  @discardableResult
  public mutating func update(temperature newTemperature: Double) -> Double {
    total += newTemperature
    samples += 1
    mean = total / Double(samples)
    return mean ?? 0
  }
}
