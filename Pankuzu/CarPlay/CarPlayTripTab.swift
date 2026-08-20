import CarPlay
import UIKit

//import DokoExtensions
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
      CPGridButton(titleVariants: ["Overview"], image: symbol("bolt.car")) { [weak self] _ in
        guard let self else { return }
        interfaceController.pushTemplate(tripOverviewTemplate!, animated: true, completion: nil)
      },
      CPGridButton(titleVariants: ["Efficiency"], image: symbol("ev.charger.fill")) { [weak self] _ in
        guard let self else { return }
        interfaceController.pushTemplate(tripEfficiencyTemplate!, animated: true, completion: nil)
      },
    ]

    let template = CPGridTemplate(title: "Trip", gridButtons: buttons)
    template.tabTitle = "Trip"
    template.tabImage = UIImage(systemName: "bolt.car")
    return template
  }

  func makeTripOverviewItems(from responses: DokoResponseDictionary) -> [CPInformationItem] {
    var items: [CPInformationItem] = []
    if case let .duration(v)?                       = responses[.duration]?.response                { items.append(.init(title: "Duration",           detail: formatDuration(v)))       }
    if case let .distance(v)?                       = responses[.distance]?.response                { items.append(.init(title: "Distance",           detail: formatDistance(v)))       }
    if case let .batteryDistanceToEmpty(v)?         = responses[.batteryDistanceToEmpty]?.response  { items.append(.init(title: "Range",              detail: formatRange(v)))          }
    if case let .batteryStateOfCharge(v)?           = responses[.batteryStateOfCharge]?.response    { items.append(.init(title: "State of Charge",    detail: formatStateOfCharge(v)))  }
    if case let .batteryEnergy(v)?                  = responses[.batteryEnergy]?.response           { items.append(.init(title: "Energy Used",        detail: formatEnergy(-v)))        }
    if case let .tripEfficiency(v)?                 = responses[.tripEfficiency]?.response          { items.append(.init(title: "Trip Efficiency",    detail: formatTripEfficiency(v))) }
    return items
  }

  func makeTripEfficiencyItems(from responses: DokoResponseDictionary) -> [CPInformationItem] {
    var items: [CPInformationItem] = []
    if case let .duration(v)?                       = responses[.duration]?.response                { items.append(.init(title: "",                   detail: formatDurationSeconds(v))) }
    if case let .tripEfficiency(v)?                 = responses[.tripEfficiency]?.response          { items.append(.init(title: "Trip Efficiency",    detail: formatTripEfficiency(v))) }
    if case let .tripEfficiency5Minute(v)?          = responses[.tripEfficiency5Minute]?.response   { items.append(.init(title: "Past 5 Minutes",     detail: formatTripEfficiency(v))) }
    if case let .tripEfficiency10Minute(v)?         = responses[.tripEfficiency10Minute]?.response  { items.append(.init(title: "Past 10 Minutes",    detail: formatTripEfficiency(v))) }
    if case let .tripEfficiency15Minute(v)?         = responses[.tripEfficiency15Minute]?.response  { items.append(.init(title: "Past 15 Minutes",    detail: formatTripEfficiency(v))) }
    return items
  }
}
