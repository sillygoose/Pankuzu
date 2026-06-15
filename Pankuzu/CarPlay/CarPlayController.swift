import CarPlay
import Observation
import UIKit
import DokoSharing

@MainActor
final class CarPlayController {
  let interfaceController: CPInterfaceController
  private var statusInfoTemplate: CPInformationTemplate?
  var chargeSessionTemplate: CPInformationTemplate?
  var chargeInputTemplate: CPInformationTemplate?
  var chargeOutputTemplate: CPInformationTemplate?
  var chargeBatteryTemplate: CPInformationTemplate?

  @Shared(.appSettings) private var appSettings
  @Shared(.connectedAccessoryName) private var connectedAccessoryName
  @Shared(.activeSession) private var activeSession
  @Shared(.chargeResponses) private var chargeResponses

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
    chargeSessionTemplate = nil
    chargeInputTemplate = nil
    chargeOutputTemplate = nil
    chargeBatteryTemplate = nil
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
      _ = chargeResponses
    } onChange: {
      Task { @MainActor [weak self] in
        guard let self else { return }
        statusInfoTemplate?.items = makeStatusItems()
        statusInfoTemplate?.actions = makeStatusActions()
        chargeSessionTemplate?.items = makeChargeSessionItems(from: chargeResponses)
        chargeInputTemplate?.items   = makeChargeInputItems(from: chargeResponses)
        chargeOutputTemplate?.items  = makeChargeOutputItems(from: chargeResponses)
        chargeBatteryTemplate?.items = makeChargeBatteryItems(from: chargeResponses)
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
