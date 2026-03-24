import SwiftUI
import MapKit

import DokoSharing

@MainActor
@Observable
class MapsSettingsModel {
  @ObservationIgnored @Shared(.appSettings) var appSettings

  init() {}

  func setTripMapStyle(_ style: DisplayMapStyle) {
    $appSettings.tripMapStyle.withLock { $0 = style }
  }

  func setChargeMapStyle(_ style: DisplayMapStyle) {
    $appSettings.chargeMapStyle.withLock { $0 = style }
  }
}

private struct MapStylePicker: View {
  @Binding var selection: DisplayMapStyle
  let pickerName: String

  var body: some View {
    Picker(
      pickerName,
      selection: $selection
    ) {
      ForEach(DisplayMapStyle.allCases) { mapStyle in
        Text(mapStyle.name)
          .fixedSize(horizontal: false, vertical: true)
          .tag(mapStyle)
      }
    }
  }
}

struct MapsSettingsView: View {
  @State private var model = MapsSettingsModel()

  var body: some View {
    List {
      MapStylePicker(
        selection: Binding(
          get: { model.appSettings.tripMapStyle },
          set: { model.setTripMapStyle($0) }
        ),
        pickerName: "Trip Map Style"
      )
      MapStylePicker(
        selection: Binding(
          get: { model.appSettings.chargeMapStyle },
          set: { model.setChargeMapStyle($0) }
        ),
        pickerName: "Charge Map Style"
      )
    }
    .listStyle(.plain)
    .navigationTitle("Maps")
  }
}

#Preview {
  NavigationStack {
    MapsSettingsView()
      .preferredColorScheme(.dark)
  }
}
