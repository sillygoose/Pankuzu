import CarPlay
import Observation
import UIKit
import DokoSharing

@MainActor
final class CarPlayController {
  private let interfaceController: CPInterfaceController
  private var listTemplate: CPListTemplate?

  @Shared(.appSettings) private var appSettings
  @Shared(.connectedAccessoryName) private var connectedAccessoryName
  @Shared(.activeSession) private var activeSession

  init(interfaceController: CPInterfaceController) {
    self.interfaceController = interfaceController
  }

  func connect() {
    let template = CPListTemplate(title: "Scan Tool Status", sections: [makeSection()])
    listTemplate = template
    interfaceController.setRootTemplate(template, animated: false, completion: nil)
    observe()
  }

  func disconnect() {
    listTemplate = nil
  }

  private func observe() {
    withObservationTracking {
      _ = appSettings.backgroundMode
      _ = connectedAccessoryName
      _ = activeSession
    } onChange: {
      Task { @MainActor [weak self] in
        guard let self else { return }
        listTemplate?.updateSections([makeSection()])
        observe()
      }
    }
  }

  private func makeSection() -> CPListSection {
    let enableItem = CPListItem(
      text: "Enable",
      detailText: appSettings.backgroundMode ? "On" : "Off",
      image: UIImage(systemName: "power")
    )
    enableItem.handler = { [weak self] _, completion in
      self?.$appSettings.backgroundMode.withLock { $0.toggle() }
      completion()
    }

    let btSymbol = connectedAccessoryName != nil
      ? "antenna.radiowaves.left.and.right"
      : "antenna.radiowaves.left.and.right.slash"
    let btItem = CPListItem(
      text: "Bluetooth",
      detailText: connectedAccessoryName ?? "Not Connected",
      image: UIImage(systemName: btSymbol)
    )

    let sessionItem = CPListItem(
      text: "Activity",
      detailText: activityDetail,
      image: activeSession.flatMap { UIImage(systemName: $0.symbol) }
    )

    return CPListSection(items: [enableItem, btItem, sessionItem])
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
