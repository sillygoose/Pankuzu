import Foundation

public struct TripEfficiency<C: Clock>: Sendable where C.Instant.Duration == Duration {
  private struct Sample: Sendable {
    let timestamp: C.Instant
    let distance: Double
    let energy: Double
  }

  private let clock: C
  private var samples: [Sample] = []

  public private(set) var efficiency: Double = 0
  public private(set) var efficiency5min: Double?
  public private(set) var efficiency10min: Double?
  public private(set) var efficiency15min: Double?

  public init(clock: C) {
    self.clock = clock
  }

  @discardableResult
  public mutating func reset() -> Double {
    samples = []
    efficiency = 0
    efficiency5min = nil
    efficiency10min = nil
    efficiency15min = nil
    return efficiency
  }

  @discardableResult
  public mutating func updateEfficiency(_ distance: Double, _ energy: Double) -> Double {
    let now = clock.now
    samples.append(Sample(timestamp: now, distance: distance, energy: energy))

    let cutoff = now.advanced(by: .seconds(-15 * 60))
    while samples.count > 1 && samples[1].timestamp <= cutoff {
      samples.removeFirst()
    }

    efficiency = energy == 0 ? 0 : distance / energy
    efficiency5min  = windowEfficiency(secondsAgo: 5  * 60, distance: distance, energy: energy, now: now)
    efficiency10min = windowEfficiency(secondsAgo: 10 * 60, distance: distance, energy: energy, now: now)
    efficiency15min = windowEfficiency(secondsAgo: 15 * 60, distance: distance, energy: energy, now: now)
    return efficiency
  }

  private func windowEfficiency(secondsAgo: Int, distance: Double, energy: Double, now: C.Instant) -> Double? {
    let cutoff = now.advanced(by: .seconds(-secondsAgo))
    guard let baseline = samples.last(where: { $0.timestamp <= cutoff }) else { return nil }
    let deltaEnergy = energy - baseline.energy
    guard deltaEnergy > 0 else { return 0 }
    return (distance - baseline.distance) / deltaEnergy
  }
}

extension TripEfficiency where C == ContinuousClock {
  public init() {
    self.init(clock: ContinuousClock())
  }
}
