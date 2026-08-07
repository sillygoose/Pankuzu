import Foundation

import DokoTypes
import DokoLogging

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
  private let movingAverageCuroffPeriod: Double = 15
  
  /// How far back (in distance) `distanceSamples` retains history — independent of and larger
  /// than `movingAverageWindow`, mirroring how `samples` retains 15 minutes regardless of the
  /// smaller 5/10-minute stat windows.
  private let distanceSampleRetention: Double = 15
  private var distanceSamples: [EfficiencySample] = []

  private let timeSampleRetention: Double = 15
  private var timeSamples: [EfficiencySample] = []
  
  public private(set) var efficiencyMovingAverage: [EfficiencyPoint] = []

  public var efficiency: Double { (rawEfficiency * 1_000).rounded() / 1_000 }
  public var efficiency5min: Double? { rawEfficiency5min.map { ($0 * 1_000).rounded() / 1_000 } }
  public var efficiency10min: Double? { rawEfficiency10min.map { ($0 * 1_000).rounded() / 1_000 } }
  public var efficiency15min: Double? { rawEfficiency15min.map { ($0 * 1_000).rounded() / 1_000 } }

  private var rawEfficiency: Double = 0
  private var rawEfficiency5min: Double?
  private var rawEfficiency10min: Double?
  private var rawEfficiency15min: Double?

  let movingAverage60Seconds = 60
  let movingAverage90Seconds = 90
  let movingAverage120Seconds = 120
  
  let fiveMinutesPrior = 5 * 60
  let tenMinutesPrior = 10 * 60
  let fifteenMinutesPrior = 15  * 60
  
  public init(clock: C, movingAverageWindow: Double = 1.0) {
    self.clock = clock
    self.movingAverageWindow = movingAverageWindow
  }

  @discardableResult
  public mutating func reset() -> Double {
    timeSamples = []
    distanceSamples = [EfficiencySample(timestamp: clock.now, distance: 0, energy: 0)]
    rawEfficiency = 0
    rawEfficiency5min = nil
    rawEfficiency10min = nil
    rawEfficiency15min = nil
    efficiencyMovingAverage = []
    return rawEfficiency
  }

  public mutating func updateEfficiency(_ distance: Double, _ energy: Double) -> Void {
    let now = clock.now
    rawEfficiency = energy == 0 ? 0 : distance / energy
    DokoLogging.shared.postLoggingResponse(.liveActivity("current(\(String(format: "%.1f", distance)), \(String(format: "%.3f", energy)) \(String(format: "%.2f", efficiency)))"), debugPacket: true)

    // Skip the degenerate (0, 0) start-of-trip state so the first real reading becomes the
    // baseline anchor for the 5/10/15-minute windows instead of an empty one.
    if rawEfficiency != 0 || !timeSamples.isEmpty {
      timeSamples.append(EfficiencySample(timestamp: now, distance: distance, energy: energy))
      let timeCutoff = now.advanced(by: .seconds(-timeSampleRetention * 60))
      while timeSamples.count > 1 && timeSamples[1].timestamp <= timeCutoff { timeSamples.removeFirst() }
    }

    rawEfficiency5min = windowEfficiency(since: fiveMinutesPrior, distance: distance, energy: energy, now: now)
    rawEfficiency10min = windowEfficiency(since: tenMinutesPrior, distance: distance, energy: energy, now: now)
    rawEfficiency15min = windowEfficiency(since: fifteenMinutesPrior, distance: distance, energy: energy, now: now)

    // Distance-based moving average: entirely independent of `samples`. A stationary vehicle
    // never changes `distance`, so this whole block — and the chart it feeds — simply stays put.
    let distanceChanged = (distanceSamples.last?.distance).map { distance != $0 } ?? true
    if distanceChanged {
      distanceSamples.append(EfficiencySample(timestamp: now, distance: distance, energy: energy))
      let distanceCutoff = distance - distanceSampleRetention
      while distanceSamples.count > 1 && distanceSamples[1].distance <= distanceCutoff { distanceSamples.removeFirst() }

      guard let nearestWindowEfficiency = nearestWindowEfficiency(since: movingAverage120Seconds, distance: distance, energy: energy, now: now) else { return }
      let roundedTimestamp = Date()
      let roundedEfficiency = (nearestWindowEfficiency * 1000).rounded() / 1000
      efficiencyMovingAverage.append(EfficiencyPoint(timestamp: roundedTimestamp, efficiency: roundedEfficiency))
      DokoLogging.shared.postLoggingResponse(.liveActivity("efficiencyMovingAverage(\(String(format: "%.2f", nearestWindowEfficiency)))"), debugPacket: true)

      let movnigAverageCutoff = Date(timeIntervalSinceNow: -movingAverageCuroffPeriod * 60)
      while efficiencyMovingAverage.count > 1 && efficiencyMovingAverage[0].timestamp <= movnigAverageCutoff {
        efficiencyMovingAverage.removeFirst()
      }
    }
    return
  }

  private func windowEfficiency(since: Int, distance: Double, energy: Double, now: C.Instant) -> Double? {
    let cutoff = now.advanced(by: .seconds(-since))
    guard let baseline = timeSamples.last(where: { $0.timestamp <= cutoff }) else { return nil }
    let deltaEnergy = energy - baseline.energy
    guard deltaEnergy > 0 else { return 0 }
    return (distance - baseline.distance) / deltaEnergy
  }

  // Unlike `windowEfficiency`, which requires a sample at or before `cutoff`, this picks
  // whichever sample's timestamp is closest to `cutoff` on either side.
  private func nearestWindowEfficiency(since: Int, distance: Double, energy: Double, now: C.Instant) -> Double? {
    let cutoff = now.advanced(by: .seconds(-since))
    guard let baseline = timeSamples.last(where: { $0.timestamp <= cutoff }) else { return nil }
    let deltaEnergy = energy - baseline.energy
    guard deltaEnergy > 0 else { return 10 }
    return (distance - baseline.distance) / deltaEnergy
  }

  private static func timeGap(_ a: C.Instant, _ b: C.Instant) -> Duration {
    let delta = a.duration(to: b)
    return delta < .zero ? .zero - delta : delta
  }
}

extension TripEfficiency where C == ContinuousClock {
  public init(movingAverageWindow: Double = 0.5) {
    self.init(clock: ContinuousClock(), movingAverageWindow: movingAverageWindow)
  }
}
