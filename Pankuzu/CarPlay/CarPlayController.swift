import CarPlay
import Observation
import UIKit
import DokoSharing

@MainActor
final class CarPlayController {
  let interfaceController: CPInterfaceController
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
