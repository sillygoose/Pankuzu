import SwiftUI

import DokoSchema

struct VehicleRow: View {
  let vehicle: Vehicle

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text("\(vehicle.yearMakeModel)")
        Text("\(vehicle.vin)")
        if let name = vehicle.name, !name.isEmpty {
          Text(name)
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
  @FetchAll var vehicles: [Vehicle]
  NavigationStack {
    List {
      VehicleRow(
        vehicle: vehicles.first!
      )
    }
    .listStyle(.plain)
    .preferredColorScheme(.dark)
  }
}
