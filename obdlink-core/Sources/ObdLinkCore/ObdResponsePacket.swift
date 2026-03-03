import Foundation

import DokoTypes

extension ObdResponsePacket {
  public var atz: String? {
    guard case let .atz(v)? = responses[.atz]?.response else { return nil }
    return v
  }
  public var ate0: String? {
    guard case .ate0? = responses[.ate0]?.response else { return nil }
    return ".ate0"
  }
  public var ath0: String? {
    guard case .ath0? = responses[.ath0]?.response else { return nil }
    return ".ath0"
  }
  public var atcaf1: String? {
    guard case .atcaf1? = responses[.atcaf1]?.response else { return nil }
    return ".atcaf1"
  }
  public var ats0: String? {
    guard case .ats0? = responses[.ats0]?.response else { return nil }
    return ".ats0"
  }
  public var stcsegr1: String? {
    guard case .stcsegr1? = responses[.stcsegr1]?.response else { return nil }
    return ".stcsegr1"
  }
  public var atsp0: String? {
    guard case .atsp0? = responses[.atsp0]?.response else { return nil }
    return ".stp33"
  }
  public var stprs: String? {
    guard case let .stprs(v)? = responses[.stprs]?.response else { return nil }
    return v
  }

//  public var stp33: String? {
//    guard case .stp33? = responses[.stp33]?.response else { return nil }
//    return ".stp33"
//  }
//  public var stp34: String? {
//    guard case .stp34? = responses[.stp34]?.response else { return nil }
//    return ".stp34"
//  }
  
  public var vin: String? {
    guard case let .vin(v)? = responses[.vin]?.response else { return nil }
    return v
  }
  
  public var gearSelected: Bool? {
    guard case let .gearSelected(v)? = responses[.gearSelected]?.response else { return nil }
    return v
  }
  
  public var obdOdometer: Double? {
    guard case let .obdOdometer(v)? = responses[.obdOdometer]?.response else { return nil }
    return v
  }

  public var odometer: Double? {
    guard case let .odometer(v)? = responses[.odometer]?.response else { return nil }
    return v
  }

  public var stateOfCharge: Double? {
    guard case let .stateOfCharge(v)? = responses[.stateOfCharge]?.response else { return nil }
    return v
  }
  
  public var energyToEmpty: Double? {
    guard case let .energyToEmpty(v)? = responses[.energyToEmpty]?.response else { return nil }
    return v
  }
  
  public var stateOfHealth: Double? {
    guard case let .stateOfHealth(v)? = responses[.stateOfHealth]?.response else { return nil }
    return v
  }
  
  public var batteryVoltage: Double? {
    guard case let .batteryVoltage(v)? = responses[.batteryVoltage]?.response else { return nil }
    return v
  }
  
  public var batteryCurrent: Double? {
    guard case let .batteryCurrent(v)? = responses[.batteryCurrent]?.response else { return nil }
    return v
  }
  
  public var distanceToEmpty: Double? {
    guard case let .distanceToEmpty(v)? = responses[.distanceToEmpty]?.response else { return nil }
    return v
  }
  
  public var batteryTemperature: Double? {
    guard case let .batteryTemperature(v)? = responses[.batteryTemperature]?.response else { return nil }
    return v
  }
  
  public var acChargerStatus: Bool? {
    guard case let .acChargerStatus(v)? = responses[.acChargerStatus]?.response else { return nil }
    return v
  }
  
  public var acChargerCouplerTemperature: Double? {
    guard case let .acChargerCouplerTemperature(v)? = responses[.acChargerCouplerTemperature]?.response else { return nil }
    return v
  }
  
  public var dcChargerStatus: Bool? {
    guard case let .dcChargerStatus(v)? = responses[.dcChargerStatus]?.response else { return nil }
    return v
  }
  
  public var dcChargerCouplerTemperature: Double? {
    guard case let .dcChargerCouplerTemperature(v)? = responses[.dcChargerCouplerTemperature]?.response else { return nil }
    return v
  }
  
  public var position: DokoPosition? {
    guard case let .position(v)? = responses[.position]?.response else { return nil }
    return v
  }
  
  public var weather: DokoCurrentWeather? {
    guard case let .weather(v)? = responses[.weather]?.response else { return nil }
    return v
  }
  
  public var meanTemperature: Double? {
    guard case let .meanTemperature(v)? = responses[.meanTemperature]?.response else { return nil }
    return v
  }
}
