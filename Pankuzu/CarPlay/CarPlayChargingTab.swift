import CarPlay
import UIKit

import DokoSharing
import DokoTypes

extension CarPlayController {
  func makeChargeTab() -> CPGridTemplate {
    chargeSessionTemplate = CPInformationTemplate(title: "Session", layout: .leading, items: [], actions: [])
    chargeInputTemplate   = CPInformationTemplate(title: "Charger Input",   layout: .leading, items: [], actions: [])
    chargeOutputTemplate  = CPInformationTemplate(title: "Charger Output",  layout: .leading, items: [], actions: [])
    chargeBatteryTemplate = CPInformationTemplate(title: "High Voltage Battery", layout: .leading, items: [], actions: [])

    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 44, weight: .regular)
    func symbol(_ name: String) -> UIImage {
      UIImage(systemName: name, withConfiguration: symbolConfig)!.withRenderingMode(.alwaysTemplate)
    }

    let buttons = [
      CPGridButton(titleVariants: ["Session"], image: symbol("gauge.medium")) { [weak self] _ in
        guard let self else { return }
        interfaceController.pushTemplate(chargeSessionTemplate!, animated: true, completion: nil)
      },
      CPGridButton(titleVariants: ["Charger Input"], image: symbol("powerplug.portrait.fill")) { [weak self] _ in
        guard let self else { return }
        interfaceController.pushTemplate(chargeInputTemplate!, animated: true, completion: nil)
      },
      CPGridButton(titleVariants: ["Charger Output"], image: symbol("ev.charger.fill")) { [weak self] _ in
        guard let self else { return }
        interfaceController.pushTemplate(chargeOutputTemplate!, animated: true, completion: nil)
      },
      CPGridButton(titleVariants: ["HV Battery"], image: symbol("batteryblock.stack.fill")) { [weak self] _ in
        guard let self else { return }
        interfaceController.pushTemplate(chargeBatteryTemplate!, animated: true, completion: nil)
      },
    ]

    let template = CPGridTemplate(title: "Charge", gridButtons: buttons)
    template.tabTitle = "Charge"
    template.tabImage = UIImage(systemName: "bolt.car")
    return template
  }

//  private func formatTemperature(_ celsius: Double) -> String {
//    let t = Measurement(value: celsius, unit: UnitTemperature.celsius)
//      .converted(to: appSettings.metric ? .celsius : .fahrenheit)
//    return String(format: "%.0f%@", t.value, t.unit.symbol)
//  }

//  private func formatDuration(_ duration: Double) -> String {
//    let duration: Duration = .seconds(duration)
//    return "\(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 2))))"
//  }

  func makeChargeSessionItems(from responses: DokoResponseDictionary) -> [CPInformationItem] {
    var items: [CPInformationItem] = []
    if case let .duration(v)?                       = responses[.duration]?.response                { items.append(.init(title: "Duration",           detail: formatDuration(v))) }
    if case let .chargerInputPower(v)?              = responses[.chargerInputPower]?.response       { items.append(.init(title: "Charger Power",      detail: String(format: "%.1f kW", v))) }
    if case let .peakPower(v)?                      = responses[.peakPower]?.response               { items.append(.init(title: "Peak Power",         detail: String(format: "%.1f kW",  v))) }
    if case let .batteryStateOfCharge(v)?           = responses[.batteryStateOfCharge]?.response    { items.append(.init(title: "State of Charge",    detail: String(format: "%.0f%%", v))) }
    if case let .batteryStateOfHealth(v)?           = responses[.batteryStateOfHealth]?.response    { items.append(.init(title: "State of Heallth",   detail: String(format: "%.0f%%", v))) }
    if case let .batteryEnergy(v)?                  = responses[.batteryEnergy]?.response           { items.append(.init(title: "Energy Added",       detail: String(format: "%.3f kWh", v))) }
    if case let .chargerInputEnergy(inputEnergy)? = responses[.chargerInputEnergy]?.response, case let .batteryEnergy(batteryEnergy)? = responses[.batteryEnergy]?.response {
      if let chargingEfficiency = chargingEfficiency(inputEnergy: inputEnergy, batteryEnergy: batteryEnergy) {
        items.append(.init(title: "Charging Efficiency", detail: String(format: "%.1f%%", chargingEfficiency)))
      }
    }
    return items
  }

  func makeChargeInputItems(from responses: DokoResponseDictionary) -> [CPInformationItem] {
    var items: [CPInformationItem] = []
    if case let .chargerInputVoltage(v)?          = responses[.chargerInputVoltage]?.response          { items.append(.init(title: "Voltage",       detail: String(format: "%.1f V",   v))) }
    if case let .chargerInputCurrent(v)?          = responses[.chargerInputCurrent]?.response          { items.append(.init(title: "Current",       detail: String(format: "%.1f A",   v))) }
    if case let .chargerInputPower(v)?            = responses[.chargerInputPower]?.response            { items.append(.init(title: "Power",         detail: String(format: "%.1f kW",  v))) }
    if case let .peakPower(v)?                    = responses[.peakPower]?.response                    { items.append(.init(title: "Peak Power",    detail: String(format: "%.1f kW",  v))) }
    if case let .chargerInputEnergy(v)?           = responses[.chargerInputEnergy]?.response           { items.append(.init(title: "Energy",        detail: String(format: "%.3f kWh", v))) }
    if case let .couplerTemperature(v)?           = responses[.couplerTemperature]?.response           { items.append(.init(title: "Coupler Temp",  detail: formatTemperature(v))) }
    if case let .secondaryCouplerTemperature(v)?  = responses[.secondaryCouplerTemperature]?.response  { items.append(.init(title: "Coupler Temp2", detail: formatTemperature(v))) }
    return items
  }

  func makeChargeOutputItems(from responses: DokoResponseDictionary) -> [CPInformationItem] {
    var items: [CPInformationItem] = []
    if case let .chargerOutputVoltage(v)? = responses[.chargerOutputVoltage]?.response { items.append(.init(title: "Voltage", detail: String(format: "%.1f V",   v))) }
    if case let .chargerOutputCurrent(v)? = responses[.chargerOutputCurrent]?.response { items.append(.init(title: "Current", detail: String(format: "%.1f A",   v))) }
    if case let .chargerOutputPower(v)?   = responses[.chargerOutputPower]?.response   { items.append(.init(title: "Power",   detail: String(format: "%.1f kW",  v))) }
    if case let .chargerOutputEnergy(v)?  = responses[.chargerOutputEnergy]?.response  { items.append(.init(title: "Energy",  detail: String(format: "%.3f kWh", v))) }
    return items
  }

  func makeChargeBatteryItems(from responses: DokoResponseDictionary) -> [CPInformationItem] {
    var items: [CPInformationItem] = []
    if case let .batteryVoltage(v)?     = responses[.batteryVoltage]?.response          { items.append(.init(title: "Voltage",          detail: String(format: "%.1f V",   v))) }
    if case let .batteryCurrent(v)?     = responses[.batteryCurrent]?.response          { items.append(.init(title: "Current",          detail: String(format: "%.1f A",   v))) }
    if case let .batteryPower(v)?       = responses[.batteryPower]?.response            { items.append(.init(title: "Power",            detail: String(format: "%.1f kW",  v))) }
    if case let .batteryEnergy(v)?      = responses[.batteryEnergy]?.response           { items.append(.init(title: "Energy",           detail: String(format: "%.3f kWh", v))) }
    if case let .batteryTemperature(v)? = responses[.batteryTemperature]?.response      { items.append(.init(title: "Temperature",      detail: formatTemperature(v))) }
    if case let .batteryStateOfHealth(v)? = responses[.batteryStateOfHealth]?.response  { items.append(.init(title: "State of Heallth", detail: String(format: "%.0f%%", v))) }
    return items
  }
}
