import SwiftUI
import MapKit

import CommonUI
import DokoLocationManager
import DokoSchema
import DokoSharing
import DokoVehicleManager

@MainActor
@Observable
public final class AddChargeFormModel: Identifiable {
  var vehicleID: Vehicle.ID?
  var timeStart: Date
  var chargerType: Charge.ChargerType = .ac
  var durationHours: Int = 0
  var durationMinutes: Int = 0
  var odometerText: String = ""
  var energyText: String = ""
  var socStartText: String = ""
  var socEndText: String = ""

  var isDismissed = false
  var saveErrorMessage: String?
  var isSaveErrorPresented = false

  @ObservationIgnored @FetchAll var vehicles: [Vehicle]
  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored @Shared(.appSettings) var appSettings

  public init(vehicleID: Vehicle.ID? = nil) {
    self.vehicleID = vehicleID
    self.timeStart = Date()
  }

  var isValid: Bool {
    vehicleID != nil &&
    chargerType != .none &&
    (durationHours > 0 || durationMinutes > 0) &&
    Double(odometerText) != nil &&
    Double(energyText) != nil &&
    Double(socStartText) != nil &&
    Double(socEndText) != nil
  }

  func cancelButtonTapped() {
    isDismissed = true
  }

  func saveButtonTapped(latitude: Double, longitude: Double) {
    guard let vehicleID, let odometerInput = Double(odometerText) else { return }

    let odometer = appSettings.metric
      ? odometerInput
      : Measurement(value: odometerInput, unit: UnitLength.miles).converted(to: .kilometers).value

    let timeEnd = timeStart.addingTimeInterval(TimeInterval(durationHours * 3600 + durationMinutes * 60))

    let locationID = DokoLocationManager.shared.addLocation(
      latitude: latitude,
      longitude: longitude,
      elevation: 0
    ) ?? UUID(0)

    var charge = Charge(
      id: UUID(),
      vehicleID: vehicleID,
      locationID: locationID,
      latitude: latitude,
      longitude: longitude,
      elevation: 0,
      timeStart: timeStart,
      timeEnd: timeEnd,
      chargerType: chargerType,
      odometer: odometer,
    )
    charge.duration = timeEnd.timeIntervalSince(timeStart)
    charge.energy = Double(energyText)
    charge.stateOfChargeStart = Double(socStartText)
    charge.stateOfChargeEnd = Double(socEndText)

    do {
      try database.write { db in
        try Charge.insert { Charge.Draft(charge) }.execute(db)
      }
      isDismissed = true
    } catch {
      reportIssue(error)
      saveErrorMessage = error.localizedDescription
      isSaveErrorPresented = true
    }
  }
}

public struct AddChargeFormView: View {
  @Environment(\.dismiss) var dismiss
  @Bindable var model: AddChargeFormModel

  @Shared(.appSettings) var appSettings
  @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
  @State private var selectedLatitude: Double = 0
  @State private var selectedLongitude: Double = 0
  @State private var searchText: String = ""
  @State private var searchResults: [MKMapItem] = []

  @FocusState private var odometerFocused: Bool
  @FocusState private var energyFocused: Bool
  @FocusState private var socStartFocused: Bool
  @FocusState private var socEndFocused: Bool

  public init(model: AddChargeFormModel) {
    self.model = model
  }

  public var body: some View {
    Form {
      Section {
        if model.vehicles.isEmpty {
          Label("No vehicles found — add one in Settings → Vehicles", systemImage: "exclamationmark.triangle")
            .font(.caption)
            .foregroundStyle(.yellow)
        } else {
          Picker("Vehicle", selection: $model.vehicleID) {
            Text("Select Vehicle").tag(nil as Vehicle.ID?)
            ForEach(model.vehicles) { vehicle in
              Text(vehicle.yearMakeModel).tag(vehicle.id as Vehicle.ID?)
            }
          }
        }

        Picker("Charger Type", selection: $model.chargerType) {
          Text("AC").tag(Charge.ChargerType.ac)
          Text("DCFC").tag(Charge.ChargerType.dc)
        }
        .pickerStyle(.segmented)
      } header: {
        Text("Session")
      }

      Section {
        DatePicker(
          "Start Time",
          selection: $model.timeStart,
          displayedComponents: [.date, .hourAndMinute]
        )

        HStack(spacing: 0) {
          Picker("Hours", selection: $model.durationHours) {
            ForEach(0..<24) { h in
              Text("\(h) h").tag(h)
            }
          }
          .pickerStyle(.wheel)
          .frame(maxWidth: .infinity)
          .clipped()

          Picker("Minutes", selection: $model.durationMinutes) {
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
        Text("When/How Long")
      }

      Section {
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundStyle(.secondary)
          TextField("Search location", text: $searchText)
            .onSubmit {
              Task { await performSearch() }
            }
          if !searchText.isEmpty {
            Button {
              searchText = ""
              searchResults = []
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
          }
        }

        ForEach(searchResults, id: \.self) { item in
          Button {
            cameraPosition = .region(MKCoordinateRegion(
              center: item.location.coordinate,
              span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
            searchText = item.name ?? ""
            searchResults = []
          } label: {
            SearchResultRow(item: item)
          }
          .buttonStyle(.plain)
        }

        Map(position: $cameraPosition)
          .frame(height: 200)
          .overlay(alignment: .center) {
            Image(systemName: "plus.circle.fill")
              .font(.title2)
              .foregroundStyle(.white)
              .shadow(radius: 3)
          }
          .onMapCameraChange { context in
            selectedLatitude = context.region.center.latitude
            selectedLongitude = context.region.center.longitude
          }
          .listRowInsets(EdgeInsets())
      } header: {
        Text("Where Did You Charge")
      }

      Section {
        HStack {
          Text("Odometer")
          Spacer()
          TextField(appSettings.metric ? "km" : "mi", text: $model.odometerText)
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
          TextField("kWh", text: $model.energyText)
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .focused($energyFocused)
            .frame(width: 60)
          Text("kWh")
            .foregroundStyle(.secondary)
        }

        HStack {
          Text("Start SoC")
          Spacer()
          TextField("%", text: $model.socStartText)
            .multilineTextAlignment(.trailing)
            .keyboardType(.numberPad)
            .focused($socStartFocused)
            .frame(width: 50)
          Text("%")
            .foregroundStyle(.secondary)
        }

        HStack {
          Text("End SoC")
          Spacer()
          TextField("%", text: $model.socEndText)
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
    .onAppear { autoSelectVehicle() }
    .onChange(of: model.vehicles) { autoSelectVehicle() }
    .onChange(of: odometerFocused) { _, focused in if focused { model.odometerText = "" } }
    .onChange(of: energyFocused) { _, focused in if focused { model.energyText = "" } }
    .onChange(of: socStartFocused) { _, focused in if focused { model.socStartText = "" } }
    .onChange(of: socEndFocused) { _, focused in if focused { model.socEndText = "" } }
    .onChange(of: model.isDismissed) { dismiss() }
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          model.cancelButtonTapped()
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          model.saveButtonTapped(
            latitude: selectedLatitude,
            longitude: selectedLongitude
          )
        }
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

  private func autoSelectVehicle() {
    if model.vehicleID == nil, model.vehicles.count == 1 {
      model.vehicleID = model.vehicles[0].id
    }
  }

  @MainActor
  private func performSearch() async {
    guard !searchText.isEmpty else { return }
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = searchText
    let response = try? await MKLocalSearch(request: request).start()
    searchResults = response?.mapItems ?? []
  }
}

private struct SearchResultRow: View {
  let item: MKMapItem
  var body: some View {
    VStack(alignment: .leading) {
      Text(item.name ?? "").foregroundStyle(.primary)
      if let subtitle = item.address?.shortAddress {
        Text(subtitle).font(.caption).foregroundStyle(.secondary)
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
    AddChargeFormView(
      model: AddChargeFormModel()
    )
    .preferredColorScheme(.dark)
    .navigationTitle("Add Charge")
    .navigationBarTitleDisplayMode(.inline)
  }
}
