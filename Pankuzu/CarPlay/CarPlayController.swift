import CarPlay
import Observation
import UIKit

import DokoExtensions
import DokoSharing

@MainActor
final class CarPlayController {
  let interfaceController: CPInterfaceController

  private var statusInfoTemplate: CPInformationTemplate?
  private var tabBarTemplate: CPTabBarTemplate?
  private var settingsTabTemplate: CPListTemplate?
  private var tripTabTemplate: CPGridTemplate?
  private var lastChargeSession: ActiveSession?

  var tripOverviewTemplate: CPInformationTemplate?
  var tripEfficiencyTemplate: CPInformationTemplate?

  var chargeSessionTemplate: CPInformationTemplate?
  var chargeInputTemplate: CPInformationTemplate?
  var chargeOutputTemplate: CPInformationTemplate?
  var chargeBatteryTemplate: CPInformationTemplate?

  @Shared(.appSettings) var appSettings
  @Shared(.connectedAccessoryName) private var connectedAccessoryName
  @Shared(.activeSession) private var activeSession
  @Shared(.chargeUpdateResponses) private var chargeResponses
  @Shared(.tripUpdateResponses) private var tripResponses

  init(interfaceController: CPInterfaceController) {
    self.interfaceController = interfaceController
  }

  func connect() {
    let infoTemplate = makeStatusInfoTemplate()
    statusInfoTemplate = infoTemplate

    let settingsTab = makeSettingsTab(pushing: infoTemplate)
    let tripTab = makeTripTab()
    let chargeTab = makeChargeTab(for: activeSession)
    settingsTabTemplate = settingsTab
    tripTabTemplate = tripTab

    let tabBar = CPTabBarTemplate(templates: [settingsTab, tripTab, chargeTab])
    tabBarTemplate = tabBar
    interfaceController.setRootTemplate(tabBar, animated: false, completion: nil)
    observe()
  }

  func disconnect() {
    statusInfoTemplate = nil
    tabBarTemplate = nil
    settingsTabTemplate = nil
    tripTabTemplate = nil
    lastChargeSession = nil
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
      _ = tripResponses
    } onChange: {
      Task { @MainActor [weak self] in
        guard let self else { return }
        statusInfoTemplate?.items = makeStatusItems()
        statusInfoTemplate?.actions = makeStatusActions()

        tripOverviewTemplate?.items = makeTripOverviewItems(from: tripResponses)
        tripEfficiencyTemplate?.items = makeTripEfficiencyItems(from: tripResponses)

        let chargeSession: ActiveSession? = (activeSession == .acCharge || activeSession == .dcCharge) ? activeSession : nil
        if chargeSession != lastChargeSession {
          lastChargeSession = chargeSession
          if let settings = settingsTabTemplate, let trip = tripTabTemplate {
            let chargeTab = makeChargeTab(for: chargeSession)
            tabBarTemplate?.updateTemplates([settings, trip, chargeTab])
          }
        }

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

extension CarPlayController {
  func chargingEfficiency(inputEnergy: Double?, batteryEnergy: Double?) -> Double? {
    guard let input = inputEnergy, let output = batteryEnergy, input > 0 else { return nil }
    return output / input * 100
  }

  func formatDistance(_ distance: Double) -> String {
    let d = Measurement(value: distance, unit: UnitLength.kilometers)
      .converted(to: appSettings.metric ? .kilometers : .miles)
    return String(format: "%.1f %@", d.value, d.unit.symbol)
  }

  func formatTripEfficiency(_ efficiency: Double) -> String {
    let e = Measurement(value: efficiency, unit: UnitEnergyEfficiency.kilometersPerKilowattHour)
      .converted(to: appSettings.metric ? .kilometersPerKilowattHour : .milesPerKilowattHour)
    return String(format: "%.2f %@", e.value, e.unit.symbol)
  }

  func formatDuration(_ duration: Double) -> String {
    let duration: Duration = .seconds(duration)
    return "\(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 2))))"
  }

  func formatDurationSeconds(_ duration: Double) -> String {
    let duration: Duration = .seconds(duration)
    return "\(duration.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2))))"
  }

  func formatTemperature(_ celsius: Double) -> String {
    let t = Measurement(value: celsius, unit: UnitTemperature.celsius)
      .converted(to: appSettings.metric ? .celsius : .fahrenheit)
    return String(format: "%.0f%@", t.value, t.unit.symbol)
  }
}
