import Foundation

import DokoTypes

extension ObdResponsePacket {
  public var atz: String? {
    guard case let .atz(v)? = responses[.atz]?.response else { return nil }
    return v
  }
  public var atd: String? {
    guard case let .atd(v)? = responses[.atd]?.response else { return nil }
    return v
  }
  public var ate: Bool? {
    guard let entry = responses.first(where: { if case .ate = $0.key { return true }; return false }),
          case let .ate(v) = entry.value.response else { return nil }
    return v
  }
  public var ath: Bool? {
    guard let entry = responses.first(where: { if case .ath = $0.key { return true }; return false }),
          case let .ath(v) = entry.value.response else { return nil }
    return v
  }
  public var atcfc: Bool? {
    guard let entry = responses.first(where: { if case .atcfc = $0.key { return true }; return false }),
          case let .atcfc(v) = entry.value.response else { return nil }
    return v
  }
  public var atcaf: Bool? {
    guard let entry = responses.first(where: { if case .atcaf = $0.key { return true }; return false }),
          case let .atcaf(v) = entry.value.response else { return nil }
    return v
  }
  public var ats: Bool? {
    guard let entry = responses.first(where: { if case .ats = $0.key { return true }; return false }),
          case let .ats(v) = entry.value.response else { return nil }
    return v
  }
  public var stcsegr: Bool? {
    guard let entry = responses.first(where: { if case .stcsegr = $0.key { return true }; return false }),
          case let .stcsegr(v) = entry.value.response else { return nil }
    return v
  }
  public var atsp: Int? {
    guard let entry = responses.first(where: { if case .atsp = $0.key { return true }; return false }),
          case let .atsp(v) = entry.value.response else { return nil }
    return v
  }
  public var atsh: String? {
    guard let entry = responses.first(where: { if case .atsh = $0.key { return true }; return false }),
          case let .atsh(v) = entry.value.response else { return nil }
    return v
  }
  public var atcp: String? {
    guard let entry = responses.first(where: { if case .atcp = $0.key { return true }; return false }),
          case let .atcp(v) = entry.value.response else { return nil }
    return v
  }
  public var atcf: String? {
    guard let entry = responses.first(where: { if case .atcf = $0.key { return true }; return false }),
          case let .atcf(v) = entry.value.response else { return nil }
    return v
  }
  public var atcra: String? {
    guard let entry = responses.first(where: { if case .atcra = $0.key { return true }; return false }),
          case let .atcra(v) = entry.value.response else { return nil }
    return v
  }
  public var atcm: String? {
    guard let entry = responses.first(where: { if case .atcm = $0.key { return true }; return false }),
          case let .atcm(v) = entry.value.response else { return nil }
    return v
  }
  public var stp: Int? {
    guard let entry = responses.first(where: { if case .stp = $0.key { return true }; return false }),
          case let .stp(v) = entry.value.response else { return nil }
    return v
  }
  public var stpbr: Int? {
    guard let entry = responses.first(where: { if case .stpbr = $0.key { return true }; return false }),
          case let .stpbr(v) = entry.value.response else { return nil }
    return v
  }
  public var stpo: String? {
    guard case let .stpo(v)? = responses[.stpo]?.response else { return nil }
    return v
  }
  public var stprs: String? {
    guard case let .stprs(v)? = responses[.stprs]?.response else { return nil }
    return v
  }

  public var vin: String? {
    guard case let .vin(v)? = responses[.vin]?.response else { return nil }
    return v
  }
  
  public var gearSelected: Bool? {
    guard case let .gearSelected(v)? = responses[.gearSelected]?.response else { return nil }
    return v
  }
  
  public var odometer: Double? {
    guard case let .odometer(v)? = responses[.odometer]?.response else { return nil }
    return v
  }

  public var speed: Double? {
    guard case let .speed(v)? = responses[.speed]?.response else { return nil }
    return v
  }

  public var batteryStateOfCharge: Double? {
    guard case let .batteryStateOfCharge(v)? = responses[.batteryStateOfCharge]?.response else { return nil }
    return v
  }
  
  public var batteryEnergyToEmpty: Double? {
    guard case let .batteryEnergyToEmpty(v)? = responses[.batteryEenergyToEmpty]?.response else { return nil }
    return v
  }
  
  public var batteryStateOfHealth: Double? {
    guard case let .batteryStateOfHealth(v)? = responses[.batteryStateOfHealth]?.response else { return nil }
    return v
  }
  
  public var batteryVoltage: Double? {
    guard case let .batteryVoltage(v)? = responses[.batteryVoltage]?.response else { return nil }
    return v
  }
  public var batteryVoltage0: Double? {
    guard case let .batteryVoltage0(v)? = responses[.batteryVoltage0]?.response else { return nil }
    return v
  }
  public var batteryVoltage1: Double? {
    guard case let .batteryVoltage1(v)? = responses[.batteryVoltage1]?.response else { return nil }
    return v
  }
  public var batteryVoltage2: Double? {
    guard case let .batteryVoltage2(v)? = responses[.batteryVoltage2]?.response else { return nil }
    return v
  }
  public var batteryVoltage3: Double? {
    guard case let .batteryVoltage3(v)? = responses[.batteryVoltage3]?.response else { return nil }
    return v
  }
  public var batteryVoltage4: Double? {
    guard case let .batteryVoltage4(v)? = responses[.batteryVoltage4]?.response else { return nil }
    return v
  }
  public var batteryVoltage5: Double? {
    guard case let .batteryVoltage5(v)? = responses[.batteryVoltage5]?.response else { return nil }
    return v
  }
  public var batteryVoltage6: Double? {
    guard case let .batteryVoltage6(v)? = responses[.batteryVoltage6]?.response else { return nil }
    return v
  }
  public var batteryVoltage7: Double? {
    guard case let .batteryVoltage7(v)? = responses[.batteryVoltage7]?.response else { return nil }
    return v
  }

  public var batteryCurrent: Double? {
    guard case let .batteryCurrent(v)? = responses[.batteryCurrent]?.response else { return nil }
    return v
  }
  public var batteryCurrent0: Double? {
    guard case let .batteryCurrent0(v)? = responses[.batteryCurrent0]?.response else { return nil }
    return v
  }
  public var batteryCurrent1: Double? {
    guard case let .batteryCurrent1(v)? = responses[.batteryCurrent1]?.response else { return nil }
    return v
  }
  public var batteryCurrent2: Double? {
    guard case let .batteryCurrent2(v)? = responses[.batteryCurrent2]?.response else { return nil }
    return v
  }
  public var batteryCurrent3: Double? {
    guard case let .batteryCurrent3(v)? = responses[.batteryCurrent3]?.response else { return nil }
    return v
  }
  public var batteryCurrent4: Double? {
    guard case let .batteryCurrent4(v)? = responses[.batteryCurrent4]?.response else { return nil }
    return v
  }
  public var batteryCurrent5: Double? {
    guard case let .batteryCurrent5(v)? = responses[.batteryCurrent5]?.response else { return nil }
    return v
  }
  public var batteryCurrent6: Double? {
    guard case let .batteryCurrent6(v)? = responses[.batteryCurrent6]?.response else { return nil }
    return v
  }
  public var batteryCurrent7: Double? {
    guard case let .batteryCurrent7(v)? = responses[.batteryCurrent7]?.response else { return nil }
    return v
  }
  
  public var batteryDistanceToEmpty: Double? {
    guard case let .batteryDistanceToEmpty(v)? = responses[.batteryDistanceToEmpty]?.response else { return nil }
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
}
