import SwiftUI

import Sharing

import DokoSharing

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var adaptorExpanded: Self {
    Self[.appStorage("BluetoothSettings-adaptorExpanded"), default: false]
  }
}

@MainActor @Observable class BluetoothSettingsModel {
  @ObservationIgnored @Shared(.backgroundMode) var backgroundMode
  @ObservationIgnored @Shared(.accessorySerialNumber) var accessorySerialNumber
  @ObservationIgnored @Shared(.connectedAccessorySerialNumber) var connectedAccessorySerialNumber

  func setBackgroundMode(_ isOn: Bool) {
    $backgroundMode.withLock { $0 = isOn }
  }

  func clearAccessorySerialNumber() {
    $accessorySerialNumber.withLock { $0 = nil }
  }

  func setAccessorySerialNumberFromConnected() {
    $accessorySerialNumber.withLock { $0 = connectedAccessorySerialNumber }
  }
}

struct BluetoothSettingsView: View {
  @Bindable var model: BluetoothSettingsModel
  @Shared(.adaptorExpanded) var connectionExpanded

  var body: some View {
    VStack(spacing: 0) {
      List {
        DisclosureGroup(
          isExpanded: Binding(
            get: { connectionExpanded },
            set: { newValue in $connectionExpanded.withLock { $0 = newValue } }
          )
        ) {
          Section {
            HStack {
              Text(model.accessorySerialNumber ?? "Any")
                .foregroundStyle(model.accessorySerialNumber == nil ? .secondary : .primary)
              Spacer()
              Button("Clear") {
                model.clearAccessorySerialNumber()
              }
              .buttonStyle(.borderless)
              .disabled(model.accessorySerialNumber == nil)

              Button("Set") {
                model.setAccessorySerialNumberFromConnected()
              }
              .buttonStyle(.borderless)
              .disabled(model.connectedAccessorySerialNumber == nil)
            }
          } header: {
            Text("Adapter Serial Number")
          } footer: {
            Text("Only connect to the OBDLink adapter with this serial number.")
              .font(.caption)
          }
        } label: {
          Text("Adapter")
        }
      }
      .listStyle(.plain)

      Divider()

      Button {
        model.setBackgroundMode(!model.backgroundMode)
      } label: {
        Label(
          model.backgroundMode ? "Disable Background Mode" : "Enable Background Mode",
          systemImage: model.backgroundMode ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash"
        )
        .frame(maxWidth: .infinity)
        .padding()
      }
      .buttonStyle(.borderedProminent)
      .tint(model.backgroundMode ? .red : .blue)
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
