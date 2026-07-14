import Foundation

import DokoTypes

public struct TripEfficiency<C: Clock>: Sendable where C.Instant.Duration == Duration {
  private struct EfficiencySample: Sendable {
    let timestamp: C.Instant
    let distance: Double
    let energy: Double
  }

  private let clock: C
  private let movingAverageWindow: Int = 60
  private var samples: [EfficiencySample] = []

  public private(set) var efficiency: Double = 0
  public private(set) var efficiency5min: Double?
  public private(set) var efficiency10min: Double?
  public private(set) var efficiency15min: Double?
  public private(set) var efficiencyMovingAverage: [EfficiencyPoint] = []

  let fiveMinutesPrior = 5  * 60
  let tenMinutesPrior = 10  * 60
  let fifteenMinutesPrior = 15  * 60

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
    efficiencyMovingAverage = []
    return efficiency
  }

  @discardableResult
  public mutating func updateEfficiency(_ distance: Double, _ energy: Double) -> Double {
    let now = clock.now
    let previousDistance = samples.last?.distance
    samples.append(EfficiencySample(timestamp: now, distance: distance, energy: energy))

    let cutoff15 = now.advanced(by: .seconds(-15 * 60))
    while samples.count > 1 && samples[1].timestamp <= cutoff15 { samples.removeFirst() }

    efficiency = energy == 0 ? 0 : distance / energy
    efficiency5min  = windowEfficiency(secondsAgo: fiveMinutesPrior, distance: distance, energy: energy, now: now)
    efficiency10min = windowEfficiency(secondsAgo: tenMinutesPrior, distance: distance, energy: energy, now: now)
    efficiency15min = windowEfficiency(secondsAgo: fifteenMinutesPrior, distance: distance, energy: energy, now: now)

    let distanceChanged = previousDistance.map { distance != $0 } ?? true
    if distanceChanged,
       let movingAverage = windowEfficiency(secondsAgo: movingAverageWindow, distance: distance, energy: energy, now: now, allowNegative: true) {
      efficiencyMovingAverage.append(EfficiencyPoint(timestamp: Date(), efficiency: movingAverage))
      let dateCutoff15 = Date(timeIntervalSinceNow: -15 * 60)
      while efficiencyMovingAverage.count > 1 && efficiencyMovingAverage[0].timestamp <= dateCutoff15 {
        efficiencyMovingAverage.removeFirst()
      }
    }
    return efficiency
  }

  private func windowEfficiency(secondsAgo: Int, distance: Double, energy: Double, now: C.Instant, allowNegative: Bool = false) -> Double? {
    let cutoff = now.advanced(by: .seconds(-secondsAgo))
    guard let baseline = samples.last(where: { $0.timestamp <= cutoff }) else { return nil }
    let deltaEnergy = energy - baseline.energy
    // Net regen (or flat) over the window: no meaningful km/kWh ratio to compute.
    // Callers charting this value treat negative as "very efficient" and clip it high.
    guard deltaEnergy > 0 else { return allowNegative ? -1 : 0 }
    return (distance - baseline.distance) / deltaEnergy
  }
}

extension TripEfficiency where C == ContinuousClock {
  public init() {
    self.init(clock: ContinuousClock())
  }
}
