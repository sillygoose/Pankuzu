import SwiftUI

import DokoLocationManager
import DokoVehicleManager
import DokoSchema

public struct ChargeRow: View {
  let charge: Charge
  
  var vehicle: Vehicle?
  var location: Location
  
  public init(
    charge: Charge
  ) {
    self.charge = charge
    self.vehicle = DokoVehicleManager.shared.lookup(id: charge.vehicleID)
    self.location = DokoLocationManager.shared.lookup(id: charge.locationID)
  }
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack {
        Text("\(charge.timeStart.formatted(date: .numeric, time: .shortened))")
        Spacer()
        if let vehicle = vehicle {
          Image(systemName: vehicle.truck ? "truck.pickup.side" : "car.side")
        } else {
          Image(systemName: "truck.pickup.side")
        }
      }
      
      Text("\(location.placeNameCityState)")
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
    .font(.body)
    .padding(.horizontal, 2)
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  @FetchAll() var charges: [Charge]
  NavigationStack {
    List {
      ChargeRow(
        charge: charges.first!
      )
    }
    .listStyle(.plain)
    .preferredColorScheme(.dark)
  }
}
