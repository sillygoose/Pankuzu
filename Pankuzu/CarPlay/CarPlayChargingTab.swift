import CarPlay
import UIKit

import DokoTypes

extension CarPlayController {
  func makeChargeTab() -> CPInformationTemplate {
    let template = CPInformationTemplate(title: "Charge", layout: .leading, items: [], actions: [])
    template.tabTitle = "Charge"
    template.tabImage = UIImage(systemName: "bolt.car")
    return template
  }

  func makeChargeItems(from responses: DokoResponseDictionary) -> [CPInformationItem] {
    var items: [CPInformationItem] = []

    // Charger Input
    if case let .chargerInputVoltage(v)?  = responses[.chargerInputVoltage]?.response  { items.append(.init(title: "Input Voltage",  detail: String(format: "%.1f V",   v))) }
    if case let .chargerInputCurrent(v)?  = responses[.chargerInputCurrent]?.response  { items.append(.init(title: "Input Current",  detail: String(format: "%.1f A",   v))) }
    if case let .chargerInputPower(v)?    = responses[.chargerInputPower]?.response    { items.append(.init(title: "Input Power",    detail: String(format: "%.2f kW",  v))) }
    if case let .chargerInputEnergy(v)?   = responses[.chargerInputEnergy]?.response   { items.append(.init(title: "Input Energy",   detail: String(format: "%.3f kWh", v))) }

    // Charger Output
    if case let .chargerOutputVoltage(v)? = responses[.chargerOutputVoltage]?.response { items.append(.init(title: "Output Voltage", detail: String(format: "%.1f V",   v))) }
    if case let .chargerOutputCurrent(v)? = responses[.chargerOutputCurrent]?.response { items.append(.init(title: "Output Current", detail: String(format: "%.1f A",   v))) }
    if case let .chargerOutputPower(v)?   = responses[.chargerOutputPower]?.response   { items.append(.init(title: "Output Power",   detail: String(format: "%.2f kW",  v))) }
    if case let .chargerOutputEnergy(v)?  = responses[.chargerOutputEnergy]?.response  { items.append(.init(title: "Output Energy",  detail: String(format: "%.3f kWh", v))) }

    // Battery
    if case let .batteryVoltage(v)?  = responses[.batteryVoltage]?.response  { items.append(.init(title: "Battery Voltage",  detail: String(format: "%.1f V",   v))) }
    if case let .batteryCurrent(v)?  = responses[.batteryCurrent]?.response  { items.append(.init(title: "Battery Current",  detail: String(format: "%.1f A",   v))) }
    if case let .batteryPower(v)?    = responses[.batteryPower]?.response    { items.append(.init(title: "Battery Power",    detail: String(format: "%.2f kW",  v))) }
    if case let .batteryEnergy(v)?   = responses[.batteryEnergy]?.response   { items.append(.init(title: "Battery Energy",   detail: String(format: "%.3f kWh", v))) }

    // Efficiency
    if case let .chargerInputPower(inputEnergy)?  = responses[.chargerInputEnergy]?.response,
       case let .batteryEnergy(batteryEnergy)?      = responses[.batteryEnergy]?.response,
       inputEnergy > 0 {
      items.append(.init(title: "AC Charging Efficiency", detail: String(format: "%.1f%%", (batteryEnergy / inputEnergy) * 100)))
    }

    return items
  }
}
