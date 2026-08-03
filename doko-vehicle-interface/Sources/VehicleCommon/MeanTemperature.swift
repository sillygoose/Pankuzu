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
  public mutating func updateMeanTemperature(with newTemperature: Double) -> Double {
    total += newTemperature
    samples += 1
    mean =  (total / Double(samples) * 10).rounded() / 10
    return mean ?? 0
  }
}
