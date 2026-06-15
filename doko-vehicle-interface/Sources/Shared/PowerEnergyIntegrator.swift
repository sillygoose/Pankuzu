import Foundation

public struct PowerEnergyIntegrator: Sendable {
  public private(set) var voltage: Double?
  public private(set) var current: Double?
  public private(set) var power: Double?
  public private(set) var energy: Double?
  private var previousPower: Double?
  private var previousUpdate: Date?

  public init() {}

  public mutating func reset() {
    voltage = nil
    current = nil
    power = nil
    energy = nil
    previousPower = nil
    previousUpdate = nil
  }

  @discardableResult
  public mutating func integrate(power newPower: Double, at date: Date) -> Double? {
    power = newPower
    if let lastTime = previousUpdate, let lastPower = previousPower {
      let deltaHours = date.timeIntervalSince(lastTime) / 3600.0
      energy = (energy ?? 0.0) + (lastPower + newPower) / 2.0 * deltaHours
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

public struct TripOdometer: Sendable {
  public private(set) var initialOdometer: Double = 0
  public private(set) var odometer: Double = 0
  public private(set) var distance: Double = 0

  public init() {}

  public mutating func reset(odometer newOdometer: Double) {
    initialOdometer = newOdometer
    odometer = newOdometer
    distance = 0
  }

  @discardableResult
  public mutating func update(odometer newOdometer: Double) -> Double {
    odometer = newOdometer
    distance += newOdometer - initialOdometer
    return distance
  }
}
