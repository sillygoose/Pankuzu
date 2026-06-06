import CarPlay
import Observation
import UIKit
import DokoSharing

@MainActor
final class CarPlayController {
  private let interfaceController: CPInterfaceController
  private var statusInfoTemplate: CPInformationTemplate?

  @Shared(.appSettings) private var appSettings
  @Shared(.connectedAccessoryName) private var connectedAccessoryName
  @Shared(.activeSession) private var activeSession

  init(interfaceController: CPInterfaceController) {
    self.interfaceController = interfaceController
  }

  func connect() {
    let infoTemplate = makeStatusInfoTemplate()
    statusInfoTemplate = infoTemplate

    let settingsTab = makeSettingsTab(pushing: infoTemplate)
    let tripTab = makeTripTab()
    let chargeTab = makeChargeTab()

    let tabBar = CPTabBarTemplate(templates: [settingsTab, tripTab, chargeTab])
    interfaceController.setRootTemplate(tabBar, animated: false, completion: nil)
    observe()
  }

  func disconnect() {
    statusInfoTemplate = nil
  }

  // MARK: - Tab construction

  private func makeSettingsTab(pushing infoTemplate: CPInformationTemplate) -> CPListTemplate {
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

  private func makeTripTab() -> CPInformationTemplate {
    let template = CPInformationTemplate(title: "Trip", layout: .leading, items: [], actions: [])
    template.tabTitle = "Trip"
    template.tabImage = UIImage(systemName: "car.rear.road.lane.dashed")
    return template
  }

  private func makeChargeTab() -> CPInformationTemplate {
    let template = CPInformationTemplate(title: "Charge", layout: .leading, items: [], actions: [])
    template.tabTitle = "Charge"
    template.tabImage = UIImage(systemName: "bolt.car")
    return template
  }

  // MARK: - Status info template

  private func makeStatusInfoTemplate() -> CPInformationTemplate {
    CPInformationTemplate(
      title: "Status",
      layout: .leading,
      items: makeStatusItems(),
      actions: makeStatusActions()
    )
  }

  private func observe() {
    withObservationTracking {
      _ = appSettings.backgroundMode
      _ = connectedAccessoryName
      _ = activeSession
    } onChange: {
      Task { @MainActor [weak self] in
        guard let self else { return }
        statusInfoTemplate?.items = makeStatusItems()
        statusInfoTemplate?.actions = makeStatusActions()
        observe()
      }
    }
  }

  private func makeStatusItems() -> [CPInformationItem] {
    [
      CPInformationItem(title: "Bluetooth", detail: connectedAccessoryName ?? "Not Connected"),
      CPInformationItem(title: "Activity", detail: activityDetail),
    ]
  }

  private func makeStatusActions() -> [CPTextButton] {
    [
      CPTextButton(
        title: appSettings.backgroundMode ? "Disable" : "Enable",
        textStyle: appSettings.backgroundMode ? .cancel : .confirm
      ) { [weak self] _ in
        self?.$appSettings.backgroundMode.withLock { $0.toggle() }
      }
    ]
  }

  private var activityDetail: String {
    switch activeSession {
    case .trip:     return "Trip in progress"
    case .acCharge: return "AC Charging"
    case .dcCharge: return "DC Charging"
    case nil:       return "None"
    }
  }
}
