import Foundation

public struct PowerEnergyIntegrator: Sendable {
  public private(set) var voltage: Double?
  public private(set) var current: Double?
  public private(set) var power: Double?
  public private(set) var peakPower: Double = 0
  public private(set) var energy: Double?
  private var previousPower: Double?
  private var previousUpdate: Date?

  public init() {}

  public mutating func reset() {
    voltage = nil
    current = nil
    power = nil
    peakPower = 0
    energy = nil
    previousPower = nil
    previousUpdate = nil
  }

  @discardableResult
  public mutating func integrate(power newPower: Double, at date: Date) -> Double? {
    power = newPower
    peakPower = max(peakPower, newPower)
    if let lastTime = previousUpdate, let lastPower = previousPower {
      let deltaHours = date.timeIntervalSince(lastTime) / 3600.0
      energy = (energy ?? 0.0) + (lastPower + newPower) / 2.0 * deltaHours
    } else {
      energy = 0
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
