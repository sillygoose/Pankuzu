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

  @discardableResult
  public mutating func updateEfficiency(_ distance: Double, _ energy: Double) -> Double {
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

      let distanceWindowCutoff = distance - movingAverageWindow
      if let baseline = distanceSamples.last(where: { $0.distance <= distanceWindowCutoff }) {
        let deltaDistance = distance - baseline.distance
        let deltaEnergy = energy - baseline.energy
        // -100 is a sentinel distinct from any real (if unusual) negative regen ratio — the
        // chart treats any negative value as "very efficient" and clips it to the top.
        let movingAverageEfficiency = deltaEnergy == 0 ? -100 : deltaDistance / deltaEnergy
        // Rounding keeps the JSON encoding of each point short (no 15-17 digit floating-point
        // noise) — this array is the dominant contributor to ContentState's size against
        // ActivityKit's 4KB limit, and the chart doesn't need sub-second/sub-milli precision.
        let roundedTimestamp = Date()
        let roundedEfficiency = (movingAverageEfficiency * 1000).rounded() / 1000
        efficiencyMovingAverage.append(EfficiencyPoint(timestamp: roundedTimestamp, efficiency: roundedEfficiency))
        DokoLogging.shared.postLoggingResponse(.liveActivity("baseline(\(String(format: "%.1f", baseline.distance)), \(String(format: "%.3f", baseline.energy)))"), debugPacket: true)
        DokoLogging.shared.postLoggingResponse(.liveActivity("efficiencyMovingAverage(\(String(format: "%.2f", movingAverageEfficiency)))"), debugPacket: true)
        let dateCutoff15 = Date(timeIntervalSinceNow: -15 * 60)
        while efficiencyMovingAverage.count > 1 && efficiencyMovingAverage[0].timestamp <= dateCutoff15 {
          efficiencyMovingAverage.removeFirst()
        }
      }
    }
    return efficiency
  }

  private func windowEfficiency(since: Int, distance: Double, energy: Double, now: C.Instant) -> Double? {
    let cutoff = now.advanced(by: .seconds(-since))
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
