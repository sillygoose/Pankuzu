import SwiftUI

import DokoLocationManager
import DokoVehicleManager
import DokoSchema

public struct TripRow: View {
  let trip: Trip

  var vehicle: Vehicle?
  var fromLocation: Location?
  var toLocation: Location?

  public init(
    trip: Trip
  ) {
    self.trip = trip
    self.vehicle = DokoVehicleManager.shared.lookup(id: trip.vehicleID)
    self.fromLocation = DokoLocationManager.shared.lookup(id: trip.originID) //### honest Location
    self.toLocation = DokoLocationManager.shared.lookup(id: trip.destinationID) //### honest Location
  }
  
  public var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text("\(trip.timeStart.formatted(date: .numeric, time: .shortened))")
        Spacer()
        if let fromLocation = fromLocation {
          Text("\(fromLocation.placeNameCityState)")
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        } else {
          Text("Error: expected honest origin")
        }
        Spacer()
        if let toLocation = toLocation {
          Text("\(toLocation.placeNameCityState)")
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        } else {
          Text("Error: expected honest destination")
        }
      }
      .font(.body)
      Spacer()
      VStack(alignment: .trailing)  {
        if let vehicle = vehicle {
          Image(systemName: vehicle.truck ? "truck.pickup.side" : "car.side")
        } else {
          Image(systemName: "truck.pickup.side")
        }
      }
      .font(.body)
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seedPreviews()
  }
  @FetchAll() var trips: [Trip]
  NavigationStack {
    List {
      TripRow(
        trip: trips.first!
      )
    }
    .listStyle(.plain)
    .preferredColorScheme(.dark)
  }
}
