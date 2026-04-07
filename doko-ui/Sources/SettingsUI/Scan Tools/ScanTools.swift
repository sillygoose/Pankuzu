import SwiftUI

import Sharing

import DokoSharing

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var adaptorExpanded: Self {
    Self[.appStorage("BluetoothSettings-adaptorExpanded"), default: false]
  }
}

@MainActor @Observable class ScantoolSettingsModel {
  @ObservationIgnored @Shared(.appSettings) var appSettings
  @ObservationIgnored @Shared(.connectedAccessorySerialNumber) var connectedAccessorySerialNumber

  func clearAccessorySerialNumber() {
    $appSettings.accessorySerialNumber.withLock { $0 = nil }
  }

  func setAccessorySerialNumberFromConnected() {
    $appSettings.accessorySerialNumber.withLock { $0 = connectedAccessorySerialNumber }
  }
}


struct ScanToolsView: View {
  @Bindable var model: ScantoolSettingsModel
  @Shared(.adaptorExpanded) var connectionExpanded

  var body: some View {
    List {
      DisclosureGroup(
        isExpanded: Binding(
          get: { connectionExpanded },
          set: { newValue in $connectionExpanded.withLock { $0 = newValue } }
        )
      ) {
        Section {
          HStack {
            Text(model.appSettings.accessorySerialNumber ?? "Any")
              .foregroundStyle(model.appSettings.accessorySerialNumber == nil ? .secondary : .primary)
            Spacer()
            Button("Clear") {
              model.clearAccessorySerialNumber()
            }
            .buttonStyle(.borderless)
            .disabled(model.appSettings.accessorySerialNumber == nil)

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
    .navigationTitle("Scan Tools")
  }
}

#Preview {
  NavigationStack {
    ScanToolsView(
      model: ScantoolSettingsModel()
    )
    .preferredColorScheme(.dark)
  }
}
