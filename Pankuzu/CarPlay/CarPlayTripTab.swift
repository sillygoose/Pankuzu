import CarPlay
import UIKit

extension CarPlayController {
  func makeTripTab() -> CPInformationTemplate {
    let template = CPInformationTemplate(title: "Trip", layout: .leading, items: [], actions: [])
    template.tabTitle = "Trip"
    template.tabImage = UIImage(systemName: "car.rear.road.lane.dashed")
    return template
  }
}
