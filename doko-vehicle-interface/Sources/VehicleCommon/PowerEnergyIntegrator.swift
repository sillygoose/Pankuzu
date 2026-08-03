import Foundation

public struct PowerEnergyIntegrator: Sendable {
  public private(set) var voltage: Double?
  public private(set) var current: Double?
  public private(set) var power: Double?
  public private(set) var peakPower: Double = 0
  public var energy: Double? { rawEnergy.map { ($0 * 1_000).rounded() / 1_000 } }

  private var rawEnergy: Double?
  private var previousPower: Double?
  private var previousUpdate: Date?

  public init() {}

  public mutating func reset() {
    voltage = nil
    current = nil
    power = nil
    peakPower = 0
    rawEnergy = nil
    previousPower = nil
    previousUpdate = nil
  }

  @discardableResult
  public mutating func integrate(power newPower: Double, at date: Date) -> Double? {
    let roundedPower = (newPower * 1_000).rounded() / 1_000
    power = roundedPower
    peakPower = max(peakPower, roundedPower)
    if let previousUpdate, let previousPower {
      let deltaHours = date.timeIntervalSince(previousUpdate) / 3600.0
      rawEnergy = (rawEnergy ?? 0) + (previousPower + newPower) / 2.0 * deltaHours
    }
    previousPower = newPower
    previousUpdate = date
    return energy
  }

  @discardableResult
  public mutating func integrate(voltage newVoltage: Double, current newCurrent: Double, at date: Date) -> Double? {
    voltage = newVoltage
    current = newCurrent
    return integrate(power: newVoltage * newCurrent * 0.001, at: date)
  }
}
