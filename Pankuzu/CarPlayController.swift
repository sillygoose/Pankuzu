import CarPlay
import Observation
import DokoSharing

@MainActor
final class CarPlayController {
  private let interfaceController: CPInterfaceController
  private var infoTemplate: CPInformationTemplate?

  @Shared(.appSettings) private var appSettings
  @Shared(.connectedAccessoryName) private var connectedAccessoryName
  @Shared(.activeSession) private var activeSession

  init(interfaceController: CPInterfaceController) {
    self.interfaceController = interfaceController
  }

  func connect() {
    let template = CPInformationTemplate(
      title: "Status",
      layout: .leading,
      items: makeItems(),
      actions: makeActions()
    )
    infoTemplate = template
    interfaceController.setRootTemplate(template, animated: false, completion: nil)
    observe()
  }

  func disconnect() {
    infoTemplate = nil
  }

  private func observe() {
    withObservationTracking {
      _ = appSettings.backgroundMode
      _ = connectedAccessoryName
      _ = activeSession
    } onChange: {
      Task { @MainActor [weak self] in
        guard let self else { return }
        infoTemplate?.items = makeItems()
        infoTemplate?.actions = makeActions()
        observe()
      }
    }
  }

  private func makeItems() -> [CPInformationItem] {
    [
      CPInformationItem(title: "Bluetooth", detail: connectedAccessoryName ?? "Not Connected"),
      CPInformationItem(title: "Activity", detail: activityDetail),
    ]
  }

  private func makeActions() -> [CPTextButton] {
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
