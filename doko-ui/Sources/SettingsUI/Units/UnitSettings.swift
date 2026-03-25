import SwiftUI

import DokoSharing

@MainActor
@Observable
class UnitsSettingsModel {
  @ObservationIgnored @Shared(.appSettings) var appSettings

  init() {}

  func metricToggleChanged(isOn: Bool) {
    $appSettings.metric.withLock { $0 = isOn }
  }

  func kWhPer100kmToggleChanged(isOn: Bool) {
    $appSettings.kWhPer100km.withLock { $0 = isOn }
  }
}

struct UnitsSettingsView: View {
  @State private var model = UnitsSettingsModel()

  var body: some View {
    List {
      Toggle(
        "Metric",
        isOn: Binding(
          get: { model.appSettings.metric },
          set: { isOn, _ in model.metricToggleChanged(isOn: isOn) }
        )
      )
      if model.appSettings.metric {
        Toggle(
          "kWh Per 100km",
          isOn: Binding(
            get: { model.appSettings.kWhPer100km },
            set: { isOn, _ in model.kWhPer100kmToggleChanged(isOn: isOn) }
          )
        )
      }
    }
    .listStyle(.plain)
    .navigationTitle("Units")
  }
}

#Preview {
  NavigationStack {
    UnitsSettingsView()
      .preferredColorScheme(.dark)
  }
}
