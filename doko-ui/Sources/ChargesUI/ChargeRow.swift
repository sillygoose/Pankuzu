import SwiftUI

import DokoLocationManager
import DokoVehicleManager
import DokoSchema

public struct ChargeRow: View {
  let charge: Charge

  var vehicle: Vehicle?
  var location: Location?

  public init(
    charge: Charge
  ) {
    self.charge = charge
    self.vehicle = DokoVehicleManager.shared.lookup(id: charge.vehicleID)
    self.location = DokoLocationManager.shared.lookup(id: charge.locationID) //### honest Location
  }

  public var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text("\(charge.timeStart.formatted(date: .numeric, time: .shortened))")
        Spacer()
        if let location = location {
          Text("\(location.placeName), \(location.cityState)")
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        } else {
          Text("In Progress")
        }
      }
      .font(.headline)
      Spacer()
      if let vehicle = vehicle {
        VStack(alignment: .trailing)  {
          Image(systemName: charge.chargerType == .ac ? "powerplug" : "ev.charger")
          Spacer()
          Image(systemName: vehicle.truck ? "truck.pickup.side" : "car.side")
        }
        .font(.headline)
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seedPreviews()
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
