import Foundation
import SwiftUI

import DokoSchema
import VehiclesUI
import CommonUI

@MainActor
@Observable
class AddVehicleModel {
  var vin: String = ""
  var isDismissed = false
  var saveErrorMessage: String?
  var isSaveErrorPresented = false

  @ObservationIgnored @FetchAll var vehicles: [Vehicle]
  @ObservationIgnored @Dependency(\.defaultDatabase) var database

  var previewVehicle: Vehicle? {
    vin.count == 17 ? Vehicle(vin: vin.uppercased()) : nil
  }

  var isDuplicate: Bool {
    vin.count == 17 && vehicles.contains(where: { $0.id == vin.uppercased() })
  }

  var isValidVIN: Bool { vin.count == 17 && Self.checkVIN(vin.uppercased()) }

  var isSupported: Bool { previewVehicle?.vehicleType != .undetermined }

  var isValid: Bool { isValidVIN && !isDuplicate && isSupported }

  private static func checkVIN(_ vin: String) -> Bool {
    let transliteration: [Character: Int] = [
      "0":0,"1":1,"2":2,"3":3,"4":4,"5":5,"6":6,"7":7,"8":8,"9":9,
      "A":1,"B":2,"C":3,"D":4,"E":5,"F":6,"G":7,"H":8,
      "J":1,"K":2,"L":3,"M":4,"N":5,"P":7,"R":9,
      "S":2,"T":3,"U":4,"V":5,"W":6,"X":7,"Y":8,"Z":9
    ]
    let weights = [8,7,6,5,4,3,2,10,0,9,8,7,6,5,4,3,2]
    let chars = Array(vin)
    guard chars.count == 17 else { return false }
    var sum = 0
    for (i, char) in chars.enumerated() {
      guard let value = transliteration[char] else { return false } // I, O, Q or invalid
      sum += value * weights[i]
    }
    let remainder = sum % 11
    let checkChar: Character = remainder == 10 ? "X" : Character(String(remainder))
    return chars[8] == checkChar
  }

  func cancelButtonTapped() { isDismissed = true }

  func saveButtonTapped() {
    guard isValid else { return }
    do {
      try database.write { db in
        try Vehicle.insert { Vehicle(vin: vin.uppercased()) }.execute(db)
      }
      isDismissed = true
    } catch {
      reportIssue(error)
      saveErrorMessage = error.localizedDescription
      isSaveErrorPresented = true
    }
  }
}

struct AddVehicleFormView: View {
  @Environment(\.dismiss) var dismiss
  @Bindable var model: AddVehicleModel

  var body: some View {
    Form {
      Section {
        HStack {
          TextField("17-character VIN", text: $model.vin)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.characters)
            .onChange(of: model.vin) { _, new in
              model.vin = String(new.uppercased().prefix(17))
            }
          if !model.vin.isEmpty {
            Button {
              model.vin = ""
            } label: {
              Image(systemName: "delete.left")
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
          }
        }
      } header: {
        Text("VIN")
      } footer: {
        Text("\(model.vin.count)/17")
          .monospacedDigit()
      }

      if model.vin.count == 17 && !model.isValidVIN {
        Section {
          Label("Invalid VIN — check digit does not match", systemImage: "xmark.circle")
            .foregroundStyle(.red)
            .font(.caption)
        }
      } else if model.isDuplicate {
        Section {
          Label("This VIN is already in your garage", systemImage: "exclamationmark.triangle")
            .foregroundStyle(.yellow)
            .font(.caption)
        }
      } else if let vehicle = model.previewVehicle {
        if vehicle.vehicleType != .undetermined {
          Section {
            LabeledContent("Year", value: vehicle.year)
            LabeledContent("Make", value: vehicle.make)
            LabeledContent("Model", value: vehicle.model)
          } header: {
            Text("Detected Vehicle")
          }
        } else {
          Section {
            Label("This vehicle is not supported", systemImage: "xmark.circle")
              .foregroundStyle(.red)
              .font(.caption)
          }
        }
      }
    }
    .onChange(of: model.isDismissed) { dismiss() }

    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { model.cancelButtonTapped() }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") { model.saveButtonTapped() }
          .disabled(!model.isValid)
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

@MainActor
@Observable
class VehicleSettingsModel {
  @ObservationIgnored @FetchAll var vehicles: [Vehicle]

  @ObservationIgnored @Dependency(\.defaultDatabase) var database

  func deleteVehicle(_ vehicle: Vehicle) {
    withErrorReporting {
      try database.write { db in
        try Vehicle
          .where { $0.id.eq(vehicle.id) }
          .delete()
          .execute(db)
      }
    }
  }
}

struct VehicleSettingsView: View {
  @Bindable var model: VehicleSettingsModel

  @State private var isAddingVehicle = false
  @State private var editVehicle: Vehicle.Draft?
  @State private var isShowingAlert: Vehicle?
  
  var body: some View {
    List {
      ForEach(model.vehicles.enumerated(), id: \.element.id) { index, vehicle in
        VehicleRow(vehicle: vehicle)
          .rowFormatter(index)
          .contentShape(Rectangle())
          .onTapGesture {
            editVehicle = Vehicle.Draft(vehicle)
          }
          .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
              isShowingAlert = vehicle
            } label: {
              HStack {
                Image(systemName: "trash")
                Text("Delete")
              }
            }
            .tint(.red)
          }
      }
    }
    .listStyle(.plain)
    .sheet(item: $isShowingAlert) { vehicle in
      VStack(spacing: 20) {
        Text("Warning!")
          .font(.headline)
        Text("Deleting a vehicle is permanent and cannot be undone.\n\nPress the 'OK' button to permanently delete this vehicle or swipe down to cancel.")
          .font(.subheadline)
          .foregroundColor(.secondary)
        Button("OK") {
          model.deleteVehicle(vehicle)
          isShowingAlert = nil
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
      }
      .frame(maxWidth: 350, maxHeight: 400,alignment: .center)
      .presentationDetents([.medium])
    }
    .sheet(item: $editVehicle) { vehicle in
      NavigationStack {
        VehicleFormView(
          model: VehicleFormModel(
            vehicle: vehicle
          )
        )
      }
      .presentationDetents([.medium])
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          isAddingVehicle = true
        } label: {
          Image(systemName: "plus")
        }
      }
    }
    .sheet(isPresented: $isAddingVehicle) {
      NavigationStack {
        AddVehicleFormView(model: AddVehicleModel())
          .navigationTitle("Add Vehicle")
          .navigationBarTitleDisplayMode(.inline)
      }
      .presentationDetents([.medium])
    }
    .navigationTitle("Vehicles")
  }
}

#Preview {
  let _ = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    VehicleSettingsView(
      model: VehicleSettingsModel()
    )
    .preferredColorScheme(.dark)
  }
}
