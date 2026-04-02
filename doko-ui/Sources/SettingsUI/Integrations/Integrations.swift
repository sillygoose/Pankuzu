import SwiftUI

import DokoSchema
import DokoSharing

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var abrpExpanded: Self {
    Self[.appStorage("Integrations-abrpExpanded"), default: true]
  }
}

@MainActor
@Observable
class IntegrationsModel {
  @ObservationIgnored @Shared(.appSettings) var appSettings
  @ObservationIgnored @FetchAll var vehicles: [Vehicle]

  init() {}

  func removeToken(forVIN vin: String) {
    $appSettings.withLock { _ = $0.abrpVehicleTokens.removeValue(forKey: vin) }
  }

  func setToken(_ token: String, forVIN vin: String) {
    $appSettings.withLock { $0.abrpVehicleTokens[vin] = token }
  }

  var configuredVehicles: [(vehicle: Vehicle, token: String)] {
    vehicles
      .compactMap { vehicle in
        guard let token = appSettings.abrpVehicleTokens[vehicle.vin] else { return nil }
        return (vehicle: vehicle, token: token)
      }
  }

  var unconfiguredVehicles: [Vehicle] {
    vehicles.filter { appSettings.abrpVehicleTokens[$0.vin] == nil }
  }
}

struct IntegrationsView: View {
  @State private var model = IntegrationsModel()
  @State private var isAddingVehicle = false
  @Shared(.abrpExpanded) var abrpExpanded

  var abrpAPIKey: String = Bundle.main.object(forInfoDictionaryKey: "ABRPAPIKey") as? String ?? ""

  var body: some View {
    List {
      if !abrpAPIKey.isEmpty {
        DisclosureGroup(
          isExpanded: Binding(
            get: { abrpExpanded },
            set: { newValue in $abrpExpanded.withLock { $0 = newValue } }
          )
        ) {
          Section {
            Toggle(
              "Enable",
              isOn: Binding(
                get: { model.appSettings.abrpEnabled },
                set: { isOn, _ in model.$appSettings.abrpEnabled.withLock { $0 = isOn } }
              )
            )
            Toggle(
              "Trip Telemetry",
              isOn: Binding(
                get: { model.appSettings.abrpSendTripUpdates },
                set: { isOn, _ in model.$appSettings.abrpSendTripUpdates.withLock { $0 = isOn } }
              )
            )
            .disabled(!model.appSettings.abrpEnabled)
            Toggle(
              "Charge Telemetry",
              isOn: Binding(
                get: { model.appSettings.abrpSendChargeUpdates },
                set: { isOn, _ in model.$appSettings.abrpSendChargeUpdates.withLock { $0 = isOn } }
              )
            )
            .disabled(!model.appSettings.abrpEnabled)
          } footer: {
            Text("Enabling A Better Route Planner will share your position and vehicle data with Iternio, the company behind ABRP.")
          }

          Section {
            ForEach(model.configuredVehicles, id: \.vehicle.vin) { entry in
              VStack(alignment: .leading, spacing: 4) {
                Text(entry.vehicle.yearMakeModel)
                  .font(.headline)
                Text(entry.vehicle.vin)
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
                Text(entry.token)
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
              }
              .padding(.vertical, 4)
            }
            .onDelete { indexSet in
              for index in indexSet {
                let vin = model.configuredVehicles[index].vehicle.vin
                model.removeToken(forVIN: vin)
              }
            }
            if !model.unconfiguredVehicles.isEmpty {
              Button {
                isAddingVehicle = true
              } label: {
                Label("Add Vehicle", systemImage: "plus")
              }
            }
          } footer: {
            Text("Vehicles with an ABRP token will stream live telemetry to A Better Route Planner while driving or charging.")
          }
        } label: {
          Text("A Better Route Planner")
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Integrations")
    .sheet(isPresented: $isAddingVehicle) {
      AddABRPVehicleSheet(model: model)
    }
  }
}

private struct AddABRPVehicleSheet: View {
  var model: IntegrationsModel

  @State private var selectedVehicle: Vehicle?
  @State private var token = ""
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section("Vehicle") {
          Picker("Vehicle", selection: $selectedVehicle) {
            Text("Select a vehicle").tag(Vehicle?.none)
            ForEach(model.unconfiguredVehicles) { vehicle in
              Text(vehicle.yearMakeModel).tag(Vehicle?.some(vehicle))
            }
          }
          .pickerStyle(.navigationLink)
        }

        Section {
          TextField("User Token", text: $token)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        } header: {
          Text("ABRP Token")
        } footer: {
          Text("Find your user token in the ABRP app under Settings → Vehicle → Live Data.")
        }
      }
      .navigationTitle("Add Vehicle")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            if let vehicle = selectedVehicle, !token.isEmpty {
              model.setToken(token, forVIN: vehicle.vin)
              dismiss()
            }
          }
          .disabled(selectedVehicle == nil || token.isEmpty)
        }
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    IntegrationsView(abrpAPIKey: "preview-key")
      .preferredColorScheme(.dark)
  }
}
