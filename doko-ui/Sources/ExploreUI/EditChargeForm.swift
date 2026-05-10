import SwiftUI

import CommonUI
import DokoSchema
import DokoSharing

@MainActor
@Observable
public final class EditChargeFormModel: Identifiable {
  var charge: Charge.Draft
  let unmodifiedCharge: Charge.Draft

  var isDismissed = false
  var saveErrorMessage: String?
  var isSaveErrorPresented = false

  @ObservationIgnored
  @Dependency(\.defaultDatabase) var database

  public init(charge: Charge.Draft) {
    self.charge = charge
    self.unmodifiedCharge = charge
  }

  var unchanged: Bool {
    charge.timeEnd == unmodifiedCharge.timeEnd &&
    charge.energy == unmodifiedCharge.energy &&
    charge.stateOfChargeEnd == unmodifiedCharge.stateOfChargeEnd &&
    charge.odometer == unmodifiedCharge.odometer
  }

  func cancelButtonTapped() {
    isDismissed = true
  }

  func saveButtonTapped() {
    charge.duration = charge.timeEnd.timeIntervalSince(charge.timeStart)
    do {
      try database.write { db in
        try Charge
          .upsert { charge }
          .execute(db)
      }
      isDismissed = true
    } catch {
      reportIssue(error)
      saveErrorMessage = error.localizedDescription
      isSaveErrorPresented = true
    }
  }
}

public struct EditChargeFormView: View {
  @Environment(\.dismiss) var dismiss
  @Bindable var model: EditChargeFormModel

  @Shared(.appSettings) var appSettings

  @State private var durationHours: Int = 0
  @State private var durationMinutes: Int = 0

  @FocusState private var odometerFocused: Bool
  @State private var odometerText: String = ""

  @FocusState private var energyFocused: Bool
  @State private var energyText: String = ""

  @FocusState private var socEndFocused: Bool
  @State private var socEndText: String = ""

  public init(model: EditChargeFormModel) {
    self.model = model
  }

  public var body: some View {
    Form {
      Section {
        HStack(spacing: 0) {
          Picker("Hours", selection: $durationHours) {
            ForEach(0..<24) { h in
              Text("\(h) h").tag(h)
            }
          }
          .pickerStyle(.wheel)
          .frame(maxWidth: .infinity)
          .clipped()

          Picker("Minutes", selection: $durationMinutes) {
            ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { m in
              Text("\(m) m").tag(m)
            }
          }
          .pickerStyle(.wheel)
          .frame(maxWidth: .infinity)
          .clipped()
        }
        .frame(height: 120)
      } header: {
        Text("Session Duration")
      }

      Section {
        HStack {
          Text("Odometer")
          Spacer()
          TextField("0", text: $odometerText)
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .focused($odometerFocused)
            .frame(width: 80)
          Text(appSettings.metric ? "km" : "mi")
            .foregroundStyle(.secondary)
        }

        HStack {
          Text("Energy Added")
          Spacer()
          TextField("kWh", text: $energyText)
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .focused($energyFocused)
            .frame(width: 60)
          Text("kWh")
            .foregroundStyle(.secondary)
        }

        HStack {
          Text("End SoC")
          Spacer()
          TextField("%", text: $socEndText)
            .multilineTextAlignment(.trailing)
            .keyboardType(.numberPad)
            .focused($socEndFocused)
            .frame(width: 50)
          Text("%")
            .foregroundStyle(.secondary)
        }
      } header: {
        Text("Charge Details")
      }
    }
    .onAppear {
      let totalSeconds = Int(model.charge.timeEnd.timeIntervalSince(model.charge.timeStart))
      durationHours = totalSeconds / 3600
      durationMinutes = ((totalSeconds % 3600) / 60 / 5) * 5
      let displayOdometer = Measurement(value: model.charge.odometer, unit: UnitLength.kilometers)
        .converted(to: appSettings.metric ? .kilometers : .miles)
      odometerText = String(format: "%.0f", displayOdometer.value)
      energyText = model.charge.energy.map { String(format: "%.1f", $0) } ?? ""
      socEndText = model.charge.stateOfChargeEnd.map { String(Int($0)) } ?? ""
    }
    .onChange(of: durationHours) { updateTimeEnd() }
    .onChange(of: durationMinutes) { updateTimeEnd() }
    .onChange(of: odometerText) { _, newText in
      let input = Double(newText) ?? 0
      model.charge.odometer = appSettings.metric
        ? input
        : Measurement(value: input, unit: UnitLength.miles).converted(to: .kilometers).value
    }
    .onChange(of: odometerFocused) { _, focused in
      if focused { odometerText = "" }
    }
    .onChange(of: energyText) { _, newText in
      if let value = Double(newText) {
        model.charge.energy = value
      }
    }
    .onChange(of: energyFocused) { _, focused in
      if focused {
        energyText = ""
      } else if Double(energyText) == nil {
        energyText = model.charge.energy.map { String(format: "%.1f", $0) } ?? ""
      }
    }
    .onChange(of: socEndText) { _, newText in
      if let value = Double(newText) {
        model.charge.stateOfChargeEnd = value
      }
    }
    .onChange(of: socEndFocused) { _, focused in
      if focused {
        socEndText = ""
      } else if Double(socEndText) == nil {
        socEndText = model.charge.stateOfChargeEnd.map { String(Int($0)) } ?? ""
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

  private func updateTimeEnd() {
    let seconds = TimeInterval(durationHours * 3600 + durationMinutes * 60)
    model.charge.timeEnd = model.charge.timeStart.addingTimeInterval(seconds)
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  @FetchAll() var charges: [Charge]
  NavigationStack {
    EditChargeFormView(
      model: EditChargeFormModel(
        charge: Charge.Draft(charges.first!)
      )
    )
    .preferredColorScheme(.dark)
    .navigationTitle("Edit Charge")
    .navigationBarTitleDisplayMode(.inline)
  }
}
