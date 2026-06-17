import CarPlay
import UIKit

import DokoExtensions
import DokoSharing
import DokoTypes

extension CarPlayController {
  func makeTripTab() -> CPGridTemplate {
    tripOverviewTemplate    = CPInformationTemplate(title: "Trip Overview", layout: .leading, items: [], actions: [])
    tripEfficiencyTemplate  = CPInformationTemplate(title: "Trip Efficiency", layout: .leading, items: [], actions: [])

    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 44, weight: .regular)
    func symbol(_ name: String) -> UIImage {
      UIImage(systemName: name, withConfiguration: symbolConfig)!.withRenderingMode(.alwaysTemplate)
    }

    let buttons = [
      CPGridButton(titleVariants: ["Overview"], image: symbol("gauge.medium")) { [weak self] _ in
        guard let self else { return }
        interfaceController.pushTemplate(tripOverviewTemplate!, animated: true, completion: nil)
      },
      CPGridButton(titleVariants: ["Efficiency"], image: symbol("powerplug.portrait.fill")) { [weak self] _ in
        guard let self else { return }
        interfaceController.pushTemplate(tripEfficiencyTemplate!, animated: true, completion: nil)
      },
    ]

    let template = CPGridTemplate(title: "Trip", gridButtons: buttons)
    template.tabTitle = "Trip"
    template.tabImage = UIImage(systemName: "bolt.car")
    return template
  }

  private func formatDistance(_ distance: Double) -> String {
    let d = Measurement(value: distance, unit: UnitLength.meters)
      .converted(to: appSettings.metric ? .kilometers : .miles)
    return String(format: "%.1f %@", d.value, d.unit.symbol)
  }

  private func formatEfficiency(_ efficiency: Double) -> String {
    let e = Measurement(value: efficiency, unit: UnitEnergyEfficiency.kilometersPerKilowattHour)
      .converted(to: appSettings.metric ? .kilometersPerKilowattHour : .milesPerKilowattHour)
    return String(format: "%.1f %@", e.value, e.unit.symbol)
  }

  private func formatDuration(_ duration: Double) -> String {
    let duration: Duration = .seconds(duration)
    return "\(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 2))))"
  }

  func makeTripOverviewItems(from responses: DokoResponseDictionary) -> [CPInformationItem] {
    var items: [CPInformationItem] = []
    if case let .duration(v)?                       = responses[.duration]?.response                { items.append(.init(title: "Duration",           detail: formatDuration(v))) }
    if case let .distance(v)?                       = responses[.distance]?.response                { items.append(.init(title: "Distance",           detail: formatDistance(v))) }
    return items
  }

  func makeTripEfficiencyItems(from responses: DokoResponseDictionary) -> [CPInformationItem] {
    var items: [CPInformationItem] = []
    if case let .tripEfficiency(v)?               = responses[.tripEfficiency]?.response            { items.append(.init(title: "Trip Efficiency",     detail: formatEfficiency(v))) }
    if case let .tripEfficiency5Minute(v)?        = responses[.tripEfficiency5Minute]?.response     { items.append(.init(title: "Past 5 Minutes",      detail: formatEfficiency(v))) }
    if case let .tripEfficiency10Minute(v)?       = responses[.tripEfficiency5Minute]?.response     { items.append(.init(title: "Past 10 Minutes",     detail: formatEfficiency(v))) }
    if case let .tripEfficiency15Minute(v)?       = responses[.tripEfficiency5Minute]?.response     { items.append(.init(title: "Past 15 Minutes",     detail: formatEfficiency(v))) }
    return items
  }
}
