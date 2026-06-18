import Testing
import Foundation
import Shared

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
    #expect(e.efficiency5min == 0)
    #expect(e.efficiency10min == 0)
    #expect(e.efficiency15min == 0)
  }

  @Test func resetClearsAll() {
    var e = TripEfficiency()
    e.updateEfficiency(10, 2)
    e.reset()
    #expect(e.efficiency == 0)
    #expect(e.efficiency5min == 0)
    #expect(e.efficiency10min == 0)
    #expect(e.efficiency15min == 0)
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

  @Test func windowEfficienciesFallBackToOverallWhenInsufficientHistory() {
    // All samples are recent (< 5 min old), so the window baseline falls back
    // to samples.first and each window efficiency equals the overall efficiency.
    var e = TripEfficiency()
    e.updateEfficiency(10, 2)   // overall = 5 km/kWh
    #expect(e.efficiency5min == 0)   // only one sample — delta energy is 0
    e.updateEfficiency(20, 4)   // overall = 5 km/kWh; delta from first = 10/2 = 5
    #expect(e.efficiency5min == 5)
    #expect(e.efficiency10min == 5)
    #expect(e.efficiency15min == 5)
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
    #expect(i.energy == 0)
  }

  @Test func resetClearsAll() {
    var i = PowerEnergyIntegrator()
    let t0 = Date()
    i.integrate(power: 5, at: t0)
    i.integrate(power: 5, at: t0.addingTimeInterval(3600))
    i.reset()
    #expect(i.power == nil)
    #expect(i.peakPower == 0)
    #expect(i.energy == 0)
  }

  @Test func firstCallStoresPowerButNoEnergy() {
    var i = PowerEnergyIntegrator()
    let result = i.integrate(power: 10, at: Date())
    #expect(i.power == 10)
    #expect(result == 0)   // no previous time → no energy yet
    #expect(i.energy == 0)
  }

  @Test func trapezoidalIntegrationConstantPower() {
    // 2 kW constant over 1 hour → 2 kWh
    var i = PowerEnergyIntegrator()
    let t0 = Date()
    i.integrate(power: 2, at: t0)
    let result = i.integrate(power: 2, at: t0.addingTimeInterval(3600))
    #expect(result == 2)
    #expect(i.energy == 2)
  }

  @Test func trapezoidalIntegrationRampingPower() {
    // 0 kW → 4 kW over 1 hour → average 2 kW → 2 kWh
    var i = PowerEnergyIntegrator()
    let t0 = Date()
    i.integrate(power: 0, at: t0)
    let result = i.integrate(power: 4, at: t0.addingTimeInterval(3600))
    #expect(result == 2)
  }

  @Test func energyAccumulatesAcrossMultipleCalls() {
    // Hour 1: 2 kW constant → 2 kWh; Hour 2: 2→4 kW → 3 kWh; total 5 kWh
    var i = PowerEnergyIntegrator()
    let t0 = Date()
    i.integrate(power: 2, at: t0)
    i.integrate(power: 2, at: t0.addingTimeInterval(3600))
    let result = i.integrate(power: 4, at: t0.addingTimeInterval(7200))
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

  @Test func voltageCurrentIntegration() {
    // 100 V × 10 A = 1000 W = 1.0 kW; over 1 hour = 1.0 kWh
    var i = PowerEnergyIntegrator()
    let t0 = Date()
    i.integrate(voltage: 100, current: 10, at: t0)
    let result = i.integrate(voltage: 100, current: 10, at: t0.addingTimeInterval(3600))
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
