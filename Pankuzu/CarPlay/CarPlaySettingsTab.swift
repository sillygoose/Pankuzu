import CarPlay
import UIKit

extension CarPlayController {
  func makeSettingsTab(pushing infoTemplate: CPInformationTemplate) -> CPListTemplate {
    let statusItem = CPListItem(text: "Scan Tool Status", detailText: nil)
    statusItem.handler = { [weak self] _, completion in
      self?.interfaceController.pushTemplate(infoTemplate, animated: true, completion: nil)
      completion()
    }
    let template = CPListTemplate(title: "Settings", sections: [CPListSection(items: [statusItem])])
    template.tabTitle = "Settings"
    template.tabImage = UIImage(systemName: "gear")
    return template
  }
}
