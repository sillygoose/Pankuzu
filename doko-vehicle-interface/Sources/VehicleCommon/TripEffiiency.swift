import Foundation

import DokoTypes

public struct TripEfficiency<C: Clock>: Sendable where C.Instant.Duration == Duration {
  private struct EfficiencySample: Sendable {
    let timestamp: C.Instant
    let distance: Double
    let energy: Double
  }

  private let clock: C
  /// Distance (same unit as the `distance` passed to `updateEfficiency`, e.g. km) over which
  /// the chart's moving average is computed. Tunable per vehicle interface — vehicle odometer
  /// resolution varies, so what smooths well for one may not for another; needs to be tried on
  /// an actual vehicle to dial in.
  private let movingAverageWindow: Double
  /// How far back (in distance) `distanceSamples` retains history — independent of and larger
  /// than `movingAverageWindow`, mirroring how `samples` retains 15 minutes regardless of the
  /// smaller 5/10-minute stat windows.
  private let distanceSampleRetention: Double = 15
  private var timeSamples: [EfficiencySample] = []
  private var distanceSamples: [EfficiencySample] = []

  public private(set) var efficiency: Double = 0
  public private(set) var efficiency5min: Double?
  public private(set) var efficiency10min: Double?
  public private(set) var efficiency15min: Double?
  public private(set) var efficiencyMovingAverage: [EfficiencyPoint] = []

  let fiveMinutesPrior = 5  * 60
  let tenMinutesPrior = 10  * 60
  let fifteenMinutesPrior = 15  * 60

  public init(clock: C, movingAverageWindow: Double = 0.5) {
    self.clock = clock
    self.movingAverageWindow = movingAverageWindow
  }

  @discardableResult
  public mutating func reset() -> Double {
    timeSamples = []
    distanceSamples = []
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
    efficiency = energy == 0 ? 0 : distance / energy

    // Skip the degenerate (0, 0) start-of-trip state so the first real reading becomes the
    // baseline anchor for the 5/10/15-minute windows instead of an empty one.
    if efficiency != 0 || !timeSamples.isEmpty {
      timeSamples.append(EfficiencySample(timestamp: now, distance: distance, energy: energy))
      let cutoff15 = now.advanced(by: .seconds(-15 * 60))
      while timeSamples.count > 1 && timeSamples[1].timestamp <= cutoff15 { timeSamples.removeFirst() }
    }

    efficiency5min  = windowEfficiency(secondsAgo: fiveMinutesPrior, distance: distance, energy: energy, now: now)
    efficiency10min = windowEfficiency(secondsAgo: tenMinutesPrior, distance: distance, energy: energy, now: now)
    efficiency15min = windowEfficiency(secondsAgo: fifteenMinutesPrior, distance: distance, energy: energy, now: now)

    // Distance-based moving average: entirely independent of `samples`. A stationary vehicle
    // never changes `distance`, so this whole block — and the chart it feeds — simply stays put.
    let distanceChanged = (distanceSamples.last?.distance).map { distance != $0 } ?? true
    if distanceChanged {
      distanceSamples.append(EfficiencySample(timestamp: now, distance: distance, energy: energy))
      let distanceCutoff = distance - distanceSampleRetention
      while distanceSamples.count > 1 && distanceSamples[1].distance <= distanceCutoff { distanceSamples.removeFirst() }

      let windowCutoff = distance - movingAverageWindow
      if let baseline = distanceSamples.last(where: { $0.distance <= windowCutoff }) {
        let deltaEnergy = energy - baseline.energy
        // -100 is a sentinel distinct from any real (if unusual) negative regen ratio — the
        // chart treats any negative value as "very efficient" and clips it to the top.
        let movingAverage = deltaEnergy == 0 ? -100 : (distance - baseline.distance) / deltaEnergy
        efficiencyMovingAverage.append(EfficiencyPoint(timestamp: Date(), efficiency: movingAverage))
        let dateCutoff15 = Date(timeIntervalSinceNow: -15 * 60)
        while efficiencyMovingAverage.count > 1 && efficiencyMovingAverage[0].timestamp <= dateCutoff15 {
          efficiencyMovingAverage.removeFirst()
        }
      }
    }
    return efficiency
  }

  private func windowEfficiency(secondsAgo: Int, distance: Double, energy: Double, now: C.Instant) -> Double? {
    let cutoff = now.advanced(by: .seconds(-secondsAgo))
    guard let baseline = timeSamples.last(where: { $0.timestamp <= cutoff }) else { return nil }
    let deltaEnergy = energy - baseline.energy
    guard deltaEnergy > 0 else { return 0 }
    return (distance - baseline.distance) / deltaEnergy
  }
}

extension TripEfficiency where C == ContinuousClock {
  public init(movingAverageWindow: Double = 0.5) {
    self.init(clock: ContinuousClock(), movingAverageWindow: movingAverageWindow)
  }
}
