import Foundation

public struct TripEfficiency: Sendable {
  private struct Sample: Sendable {
    let timestamp: Date
    let distance: Double  // cumulative km
    let energy: Double    // cumulative kWh
  }

  private var samples: [Sample] = []

  public private(set) var efficiency: Double = 0
  public private(set) var efficiency5min: Double = 0
  public private(set) var efficiency10min: Double = 0
  public private(set) var efficiency15min: Double = 0

  public init() {}

  public mutating func reset() {
    samples = []
    efficiency = 0
    efficiency5min = 0
    efficiency10min = 0
    efficiency15min = 0
  }

  public mutating func updateEfficiency(_ distance: Double, _ energy: Double) {
    let now = Date()
    samples.append(Sample(timestamp: now, distance: distance, energy: energy))

    // Keep one sample just before the 15-min boundary so all window queries have a baseline
    let cutoff = now.addingTimeInterval(-15 * 60)
    while samples.count > 1 && samples[1].timestamp <= cutoff {
      samples.removeFirst()
    }

    efficiency = energy > 0 ? distance / energy : 0
    efficiency5min  = windowEfficiency(seconds: 5  * 60, distance: distance, energy: energy, now: now)
    efficiency10min = windowEfficiency(seconds: 10 * 60, distance: distance, energy: energy, now: now)
    efficiency15min = windowEfficiency(seconds: 15 * 60, distance: distance, energy: energy, now: now)
  }

  private func windowEfficiency(seconds: TimeInterval, distance: Double, energy: Double, now: Date) -> Double {
    let cutoff = now.addingTimeInterval(-seconds)
    guard let baseline = samples.last(where: { $0.timestamp <= cutoff }) else { return 0 }
    let deltaEnergy = energy - baseline.energy
    guard deltaEnergy > 0 else { return 0 }
    return (distance - baseline.distance) / deltaEnergy
  }
}
