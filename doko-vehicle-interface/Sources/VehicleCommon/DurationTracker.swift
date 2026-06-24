import Foundation

public struct DurationTracker: Sendable {
  public private(set) var start: Date = Date()
  public private(set) var current: Date = Date()
  public private(set) var duration: Double = 0

  public init() {}

  @discardableResult
  public mutating func reset() -> Double {
    start = Date.now
    current = Date.now
    duration = 0
    return duration
  }

  @discardableResult
  public mutating func update() -> Double {
    current = Date.now
    duration = current.timeIntervalSince(start)
    return duration
  }
}
