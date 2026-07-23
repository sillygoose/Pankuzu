import SwiftUI

import CommonUI
import DokoSchema

@MainActor
@Observable
public final class VehicleFormModel: Identifiable {
  var vehicle: Vehicle.Draft
  let unmodifiedVehicle: Vehicle.Draft

  var isDismissed = false
  var saveErrorMessage: String?
  var isSaveErrorPresented = false

  @ObservationIgnored
  @Dependency(\.defaultDatabase) var database

  public init(
    vehicle: Vehicle.Draft
  ) {
    self.vehicle = vehicle
    self.unmodifiedVehicle = vehicle
  }

  var unchanged: Bool {
    return vehicle == unmodifiedVehicle
  }

  func cancelButtonTapped() {
    isDismissed = true
  }

  private func trimmed(_ string: String?) -> String? {
    guard let trimmed = string?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
    return trimmed
  }

  func saveButtonTapped() {
    vehicle.name = trimmed(vehicle.name)
    do {
      try database.write { db in
        let _ = try Vehicle
          .upsert { vehicle }
          .returning(\.id)
          .fetchOne(db)
      }
      isDismissed = true
    } catch {
      reportIssue(error)
      saveErrorMessage = error.localizedDescription
      isSaveErrorPresented = true
    }
  }
}

public struct VehicleFormView: View {
  @Environment(\.dismiss) var dismiss
  @Bindable var model: VehicleFormModel

  public init(model: VehicleFormModel) {
    self.model = model
  }

  public var body: some View {
    Form {
      Section {
        HStack {
          Text("VIN:")
          Spacer()
          Text(model.vehicle.vin)
        }
        .opacity(DesignTokens.Opacity.muted)

        HStack {
          Text("Year:")
          Spacer()
          Text(model.vehicle.year)
        }
        .opacity(DesignTokens.Opacity.muted)

        HStack {
          Text("Make:")
          Spacer()
          Text(model.vehicle.make)
        }
        .opacity(DesignTokens.Opacity.muted)

        HStack {
          Text("Model:")
          Spacer()
          Text(model.vehicle.model)
        }
        .opacity(DesignTokens.Opacity.muted)

        HStack {
          Text("Nickname:")
          Spacer()
          TextField("Nickname", text: Binding(
            get: { model.vehicle.name ?? "" },
            set: { model.vehicle.name = $0.isEmpty ? nil : $0 }
          ))
          .multilineTextAlignment(.trailing)
        }
      } header: {
          Text("Vehicle Info")
        }
    }
    .onChange(of: model.isDismissed) {
      dismiss()
    }
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          model.cancelButtonTapped()
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          model.saveButtonTapped()
        }
        .disabled(model.unchanged)
      }
    }
    .alert(
      "Save error",
      isPresented: $model.isSaveErrorPresented,
      presenting: model.saveErrorMessage
    ) { _ in } message: { message in
      Text(message)
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  @FetchAll() var vehicles: [Vehicle]
  NavigationStack {
    VehicleFormView(
      model: VehicleFormModel(
        vehicle: Vehicle.Draft(vehicles.first!)
      )
    )
    .preferredColorScheme(.dark)
    .navigationTitle("Vehicle")
    .navigationBarTitleDisplayMode(.inline)
  }
}
