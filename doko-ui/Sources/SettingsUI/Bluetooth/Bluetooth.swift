import SwiftUI

import Sharing

import DokoSharing

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var connectionExpanded: Self {
    Self[.appStorage("BluetoothSettings-connectionExpanded"), default: false]
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
  @Shared(.connectionExpanded) var connectionExpanded

  var body: some View {
    List {
      DisclosureGroup(
        isExpanded: Binding(
          get: { connectionExpanded },
          set: { newValue in $connectionExpanded.withLock { $0 = newValue } }
        )
      ) {
        Section {
          Toggle(
            "Background Operation",
            isOn: Binding(
              get: { model.backgroundMode },
              set: { isOn, _ in model.setBackgroundMode(isOn) }
            )
          )
        } header: {
          Text("OBDLink Adapter")
        } footer: {
          Text("Enable to allow the OBDLink adapter to connect and operate in the background recording trips and charges.")
            .font(.caption)
        }

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
          Text("Accessory Serial Number")
        } footer: {
          Text("Only connect to the OBDLink adapter with this serial number.")
            .font(.caption)
        }
      } label: {
        Text("Connection")
      }
    }
    .listStyle(.plain)
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
