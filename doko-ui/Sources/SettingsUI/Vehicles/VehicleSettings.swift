import Foundation
import SwiftUI

import Sharing

import DokoSchema
import VehiclesUI
import CommonUI

@MainActor
@Observable
class VehicleSettingsModel {
  @ObservationIgnored
  @FetchAll var vehicles: [Vehicle]

  @ObservationIgnored
  @Dependency(\.defaultDatabase) var database

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
