import SwiftUI

import Sharing

import DokoSharing

@MainActor @Observable class BluetoothSettingsModel {
  @ObservationIgnored @Shared(.appSettings) var appSettings

  func setBackgroundMode(_ isOn: Bool) {
    $appSettings.backgroundMode.withLock { $0 = isOn }
  }
}

struct BluetoothSettingsView: View {
  @Bindable var model: BluetoothSettingsModel

  var body: some View {
    VStack(spacing: 0) {
      Button {
        model.setBackgroundMode(!model.appSettings.backgroundMode)
      } label: {
        Label(
          model.appSettings.backgroundMode ? "Disable Background Mode" : "Enable Background Mode",
          systemImage: model.appSettings.backgroundMode ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash"
        )
        .frame(maxWidth: .infinity)
        .padding()
      }
      .buttonStyle(.borderedProminent)
      .tint(model.appSettings.backgroundMode ? .red : .blue)
      .padding()
    }
    .navigationTitle("Bluetooth")
  }
}

#Preview {
  NavigationStack {
    BluetoothSettingsView(
      model: BluetoothSettingsModel()
    )
    .preferredColorScheme(.dark)
  }
}
