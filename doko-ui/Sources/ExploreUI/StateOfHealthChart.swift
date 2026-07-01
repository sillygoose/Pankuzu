import SwiftUI

import DokoSchema
import DokoSharing
import CommonUI

extension SharedKey where Self == AppStorageKey<Vehicle.ID?>.Default {
  static var stateOfHealthDisplayVehicleID: Self {
    Self[.appStorage("StateOfHealthDisplayVehicleID"), default: nil]
  }
}

@MainActor
@Observable
private final class StateOfHealthChartModel {
  @ObservationIgnored @FetchAll var vehicles: [Vehicle]
  @ObservationIgnored @Shared(.stateOfHealthDisplayVehicleID) var selectedVehicleID

  var effectiveVehicleID: Vehicle.ID? {
    if let id = selectedVehicleID, vehicles.contains(where: { $0.id == id }) {
      return id
    }
    return vehicles.first?.id
  }

  var effectiveVehicle: Vehicle? {
    guard let id = effectiveVehicleID else { return nil }
    return vehicles.first(where: { $0.id == id })
  }

  var vehicleButtonTitle: String {
    effectiveVehicle?.yearMakeModel ?? "Select Vehicle"
  }

  var vehicleButtonImage: String {
    effectiveVehicle?.truck == true ? "truck.pickup.side" : "car.side"
  }

  func selectVehicle(_ id: Vehicle.ID) {
    $selectedVehicleID.withLock { $0 = id }
  }
}

struct StateOfHealthExploreView: View {
  @State private var model = StateOfHealthChartModel()

  var body: some View {
    Group {
      if let vehicleID = model.effectiveVehicleID {
        VStack(spacing: 0) {
          if model.vehicles.count > 1 {
            Menu {
              ForEach(model.vehicles) { vehicle in
                Button {
                  model.selectVehicle(vehicle.id)
                } label: {
                  Text(vehicle.yearMakeModel)
                  Image(systemName: model.effectiveVehicleID == vehicle.id
                    ? "checkmark"
                    : (vehicle.truck ? "truck.pickup.side" : "car.side"))
                }
              }
            } label: {
              GridButton(color: .teal, symbolName: model.vehicleButtonImage, title: model.vehicleButtonTitle) {}
            }
            .padding(.horizontal)
            .padding(.top, 20)
          }
          HistoryContent(vehicleID: vehicleID)
            .id(vehicleID)
        }
      } else {
        ContentUnavailableView(
          "No Vehicles",
          systemImage: "car",
          description: Text("Add a vehicle to view State of Health history.")
        )
        .navigationTitle("State of Health History")
        .navigationBarTitleDisplayMode(.inline)
      }
    }
  }
}

private struct HistoryContent: View {
  let vehicleID: Vehicle.ID
  @State private var historyModel: StateOfHealthHistoryModel

  init(vehicleID: Vehicle.ID) {
    self.vehicleID = vehicleID
    _historyModel = State(initialValue: StateOfHealthHistoryModel(vehicleID: vehicleID, currentID: UUID()))
  }

  var body: some View {
    StateOfHealthHistoryView(model: historyModel)
  }
}
