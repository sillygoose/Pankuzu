import CarPlay
import UIKit

import DokoTypes

extension CarPlayController {
  func makeChargeTab() -> CPListTemplate {
    let template = CPListTemplate(title: "Charge", sections: [])
    template.tabTitle = "Charge"
    template.tabImage = UIImage(systemName: "bolt.car")
    return template
  }

  func makeChargeSections(from responses: DokoResponseDictionary) -> [CPListSection] {
    var sections: [CPListSection] = []

    // Charger Input
    var inputItems: [CPListItem] = []
    if case let .chargerInputVoltage(v)?  = responses[.chargerInputVoltage]?.response  { inputItems.append(.init(text: "Voltage", detailText: String(format: "%.1f V",   v))) }
    if case let .chargerInputCurrent(v)?  = responses[.chargerInputCurrent]?.response  { inputItems.append(.init(text: "Current", detailText: String(format: "%.1f A",   v))) }
    if case let .chargerInputPower(v)?    = responses[.chargerInputPower]?.response    { inputItems.append(.init(text: "Power",   detailText: String(format: "%.2f kW",  v))) }
    if case let .chargerInputEnergy(v)?   = responses[.chargerInputEnergy]?.response   { inputItems.append(.init(text: "Energy",  detailText: String(format: "%.3f kWh", v))) }
    if !inputItems.isEmpty { sections.append(CPListSection(items: inputItems, header: "Charger Input", sectionIndexTitle: nil)) }

    // Charger Output
    var outputItems: [CPListItem] = []
    if case let .chargerOutputVoltage(v)? = responses[.chargerOutputVoltage]?.response { outputItems.append(.init(text: "Voltage", detailText: String(format: "%.1f V",   v))) }
    if case let .chargerOutputCurrent(v)? = responses[.chargerOutputCurrent]?.response { outputItems.append(.init(text: "Current", detailText: String(format: "%.1f A",   v))) }
    if case let .chargerOutputPower(v)?   = responses[.chargerOutputPower]?.response   { outputItems.append(.init(text: "Power",   detailText: String(format: "%.2f kW",  v))) }
    if case let .chargerOutputEnergy(v)?  = responses[.chargerOutputEnergy]?.response  { outputItems.append(.init(text: "Energy",  detailText: String(format: "%.3f kWh", v))) }
    if !outputItems.isEmpty { sections.append(CPListSection(items: outputItems, header: "Charger Output", sectionIndexTitle: nil)) }

    // Battery
    var batteryItems: [CPListItem] = []
    if case let .batteryVoltage(v)?  = responses[.batteryVoltage]?.response  { batteryItems.append(.init(text: "Voltage", detailText: String(format: "%.1f V",   v))) }
    if case let .batteryCurrent(v)?  = responses[.batteryCurrent]?.response  { batteryItems.append(.init(text: "Current", detailText: String(format: "%.1f A",   v))) }
    if case let .batteryPower(v)?    = responses[.batteryPower]?.response    { batteryItems.append(.init(text: "Power",   detailText: String(format: "%.2f kW",  v))) }
    if case let .batteryEnergy(v)?   = responses[.batteryEnergy]?.response   { batteryItems.append(.init(text: "Energy",  detailText: String(format: "%.3f kWh", v))) }
    if !batteryItems.isEmpty { sections.append(CPListSection(items: batteryItems, header: "Battery", sectionIndexTitle: nil)) }

    // Efficiency (output / input power, shown as a standalone trailing section)
    if case let .chargerInputPower(inP)?  = responses[.chargerInputPower]?.response,
       case let .batteryPower(outP)? = responses[.batteryPower]?.response,
       inP > 0 {
      let efficiency = (outP / inP) * 100
      let item = CPListItem(text: "Charging Efficiency", detailText: String(format: "%.1f%%", efficiency))
      sections.append(CPListSection(items: [item], header: nil, sectionIndexTitle: nil))
    }

    return sections
  }
}
