import Testing
import Foundation
import VehicleCommon

// Minimal controllable clock for tests. A class so that advancing it is
// visible through the reference stored inside TripEfficiency.
private final class ManualClock: Clock, @unchecked Sendable {
  typealias Duration = Swift.Duration
  struct Instant: InstantProtocol {
    var offset: Duration = .zero
    func advanced(by duration: Duration) -> Self { .init(offset: offset + duration) }
    func duration(to other: Self) -> Duration { other.offset - offset }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.offset < rhs.offset }
  }
  var now = Instant()
  var minimumResolution: Duration { .nanoseconds(1) }
  func sleep(until deadline: Instant, tolerance: Duration?) async throws {}
  func advance(by duration: Duration) { now = now.advanced(by: duration) }
}

// MARK: - TripOdometer

@Suite("TripOdometer")
struct TripOdometerTests {

  @Test func initialState() {
    let o = TripOdometer()
    #expect(o.odometer == 0)
    #expect(o.distance == 0)
  }

  @Test func setOdometerInitializesDistance() {
    var o = TripOdometer()
    let returned = o.setOdometer(with: 50_000)
    #expect(returned == 0)
    #expect(o.odometer == 50_000)
    #expect(o.distance == 0)
  }

  @Test func updateOdometerComputesDistance() {
    var o = TripOdometer()
    o.setOdometer(with: 50_000)
    let returned = o.updateOdometer(with: 50_010)
    #expect(returned == 10)
    #expect(o.distance == 10)
    #expect(o.odometer == 50_010)
  }

  @Test func multipleUpdatesAccumulate() {
    var o = TripOdometer()
    o.setOdometer(with: 100)
    o.updateOdometer(with: 105)
    let returned = o.updateOdometer(with: 115)
    #expect(returned == 15)
    #expect(o.distance == 15)
  }

  @Test func resetViaSetOdometerClearsDistance() {
    var o = TripOdometer()
    o.setOdometer(with: 100)
    o.updateOdometer(with: 120)
    o.setOdometer(with: 200)
    #expect(o.distance == 0)
    #expect(o.odometer == 200)
  }

  @Test func updateWithSameValueYieldsZeroDistance() {
    var o = TripOdometer()
    o.setOdometer(with: 500)
    let returned = o.updateOdometer(with: 500)
    #expect(returned == 0)
  }
}

// MARK: - TripEfficiency

@Suite("TripEfficiency")
struct TripEfficiencyTests {

  @Test func initialState() {
    let e = TripEfficiency()
    #expect(e.efficiency == 0)
    #expect(e.efficiency5min == nil)
    #expect(e.efficiency10min == nil)
    #expect(e.efficiency15min == nil)
  }

  @Test func resetClearsAll() {
    var e = TripEfficiency()
    e.updateEfficiency(10, 2)
    e.reset()
    #expect(e.efficiency == 0)
    #expect(e.efficiency5min == nil)
    #expect(e.efficiency10min == nil)
    #expect(e.efficiency15min == nil)
  }

  @Test func overallEfficiencyIsDistanceOverEnergy() {
    var e = TripEfficiency()
    let returned = e.updateEfficiency(10, 2)
    #expect(returned == 5)       // 10 km / 2 kWh = 5 km/kWh
    #expect(e.efficiency == 5)
  }

  @Test func zeroEnergyYieldsZeroEfficiency() {
    var e = TripEfficiency()
    let returned = e.updateEfficiency(10, 0)
    #expect(returned == 0)
    #expect(e.efficiency == 0)
  }

  @Test func windowEfficienciesAreNilWithoutOldEnoughSamples() {
    // Both updates happen at the same instant — no window has a baseline.
    let clock = ManualClock()
    var e = TripEfficiency(clock: clock)
    e.updateEfficiency(10, 2)
    e.updateEfficiency(20, 4)
    #expect(e.efficiency5min == nil)
    #expect(e.efficiency10min == nil)
    #expect(e.efficiency15min == nil)
  }

  @Test func efficiency5minAppearsAfter5Minutes() throws {
    let clock = ManualClock()
    var e = TripEfficiency(clock: clock)
    e.updateEfficiency(10, 2)                        // t = 0
    clock.advance(by: .seconds(5 * 60 + 1))         // t = 5:01
    e.updateEfficiency(20, 4)
    // baseline: distance=10, energy=2 → delta 10km / 2kWh = 5 km/kWh
    let eff5 = try #require(e.efficiency5min)
    #expect(eff5 == 5)
    #expect(e.efficiency10min == nil)
    #expect(e.efficiency15min == nil)
  }

  @Test func efficiency10minAppearsAfter10Minutes() throws {
    let clock = ManualClock()
    var e = TripEfficiency(clock: clock)
    e.updateEfficiency(10, 2)                        // t = 0
    clock.advance(by: .seconds(10 * 60 + 1))        // t = 10:01
    e.updateEfficiency(20, 4)
    let eff5  = try #require(e.efficiency5min)
    let eff10 = try #require(e.efficiency10min)
    #expect(eff5  == 5)
    #expect(eff10 == 5)
    #expect(e.efficiency15min == nil)
  }

  @Test func efficiency15minAppearsAfter15Minutes() throws {
    let clock = ManualClock()
    var e = TripEfficiency(clock: clock)
    e.updateEfficiency(10, 2)                        // t = 0
    clock.advance(by: .seconds(15 * 60 + 1))        // t = 15:01
    e.updateEfficiency(20, 4)
    let eff5  = try #require(e.efficiency5min)
    let eff10 = try #require(e.efficiency10min)
    let eff15 = try #require(e.efficiency15min)
    #expect(eff5  == 5)
    #expect(eff10 == 5)
    #expect(eff15 == 5)
  }

  @Test func windowUsesNearestBaselineNotOldest() throws {
    // Samples at t=0, t=3min, t=8:01 (current).
    // 5-min baseline should be the t=3 sample, not t=0.
    let clock = ManualClock()
    var e = TripEfficiency(clock: clock)
    e.updateEfficiency(10, 2)                        // t = 0:    10km, 2kWh
    clock.advance(by: .seconds(3 * 60))
    e.updateEfficiency(16, 3)                        // t = 3:00: 16km, 3kWh
    clock.advance(by: .seconds(5 * 60 + 1))
    e.updateEfficiency(22, 4)                        // t = 8:01: 22km, 4kWh
    // 5-min cutoff = t=3:01 → baseline is t=3 sample
    // delta: (22-16)/(4-3) = 6 km/kWh
    let eff5 = try #require(e.efficiency5min)
    #expect(eff5 == 6)
  }

  @Test func resetReturnValue() {
    var e = TripEfficiency()
    e.updateEfficiency(20, 4)
    let returned = e.reset()
    #expect(returned == 0)
  }
}

// MARK: - PowerEnergyIntegrator

@Suite("PowerEnergyIntegrator")
struct PowerEnergyIntegratorTests {

  @Test func initialState() {
    let i = PowerEnergyIntegrator()
    #expect(i.voltage == nil)
    #expect(i.current == nil)
    #expect(i.power == nil)
    #expect(i.peakPower == 0)
    #expect(i.energy == nil)
  }

  @Test func resetClearsAll() {
    var i = PowerEnergyIntegrator()
    let t0 = Date()
    i.integrate(power: 5, at: t0)
    i.integrate(power: 5, at: t0.addingTimeInterval(3600))
    i.reset()
    #expect(i.power == nil)
    #expect(i.peakPower == 0)
    #expect(i.energy == nil)
  }

  @Test func firstCallStoresPowerButNoEnergy() {
    var i = PowerEnergyIntegrator()
    let result = i.integrate(power: 10, at: Date())
    #expect(i.power == 10)
    #expect(result == nil)   // no previous time → no energy yet
    #expect(i.energy == nil)
  }

  @Test func trapezoidalIntegrationConstantPower() throws {
    // 2 kW constant over 1 hour → 2 kWh
    var i = PowerEnergyIntegrator()
    let t0 = Date()
    i.integrate(power: 2, at: t0)
    let result = #require(i.integrate(power: 2, at: t0.addingTimeInterval(3600)))
    #expect(result == 2)
    #expect(i.energy == 2)
  }

  @Test func trapezoidalIntegrationRampingPower() throws {
    // 0 kW → 4 kW over 1 hour → average 2 kW → 2 kWh
    var i = PowerEnergyIntegrator()
    let t0 = Date()
    i.integrate(power: 0, at: t0)
    let result = #require(i.integrate(power: 4, at: t0.addingTimeInterval(3600)))
    #expect(result == 2)
  }

  @Test func energyAccumulatesAcrossMultipleCalls() throws {
    // Hour 1: 2 kW constant → 2 kWh; Hour 2: 2→4 kW → 3 kWh; total 5 kWh
    var i = PowerEnergyIntegrator()
    let t0 = Date()
    i.integrate(power: 2, at: t0)
    i.integrate(power: 2, at: t0.addingTimeInterval(3600))
    let result = #require(i.integrate(power: 4, at: t0.addingTimeInterval(7200)))
    #expect(result == 5)
  }

  @Test func peakPowerTracksMaximum() {
    var i = PowerEnergyIntegrator()
    let t0 = Date()
    i.integrate(power: 3, at: t0)
    i.integrate(power: 7, at: t0.addingTimeInterval(1))
    i.integrate(power: 5, at: t0.addingTimeInterval(2))
    #expect(i.peakPower == 7)
  }

  @Test func voltageCurrentIntegration() throws {
    // 100 V × 10 A = 1000 W = 1.0 kW; over 1 hour = 1.0 kWh
    var i = PowerEnergyIntegrator()
    let t0 = Date()
    i.integrate(voltage: 100, current: 10, at: t0)
    let result = #require(i.integrate(voltage: 100, current: 10, at: t0.addingTimeInterval(3600)))
    #expect(i.voltage == 100)
    #expect(i.current == 10)
    #expect(i.power == 1.0)
    #expect(result == 1.0)
  }
}

// MARK: - MeanTemperature

@Suite("MeanTemperature")
struct MeanTemperatureTests {

  @Test func initialState() {
    let m = MeanTemperature()
    #expect(m.total == 0)
    #expect(m.samples == 0)
    #expect(m.mean == nil)
  }

  @Test func singleSampleMeanEqualsValue() {
    var m = MeanTemperature()
    let returned = m.updateMeanTemperature(with: 22.5)
    #expect(returned == 22.5)
    #expect(m.mean == 22.5)
    #expect(m.samples == 1)
    #expect(m.total == 22.5)
  }

  @Test func multipleSamplesComputeRunningMean() {
    var m = MeanTemperature()
    m.updateMeanTemperature(with: 10)
    m.updateMeanTemperature(with: 20)
    let returned = m.updateMeanTemperature(with: 30)
    #expect(returned == 20)
    #expect(m.mean == 20)
    #expect(m.samples == 3)
    #expect(m.total == 60)
  }

  @Test func resetClearsAll() {
    var m = MeanTemperature()
    m.updateMeanTemperature(with: 15)
    m.reset()
    #expect(m.total == 0)
    #expect(m.samples == 0)
    #expect(m.mean == nil)
  }

  @Test func negativeTemperatures() {
    var m = MeanTemperature()
    m.updateMeanTemperature(with: -10)
    let returned = m.updateMeanTemperature(with: 10)
    #expect(returned == 0)
    #expect(m.mean == 0)
  }
}
