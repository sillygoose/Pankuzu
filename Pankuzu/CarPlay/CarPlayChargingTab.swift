import CarPlay
import UIKit

extension CarPlayController {
  func makeChargeTab() -> CPInformationTemplate {
    let template = CPInformationTemplate(title: "Charge", layout: .leading, items: [], actions: [])
    template.tabTitle = "Charge"
    template.tabImage = UIImage(systemName: "bolt.car")
    return template
  }
}
