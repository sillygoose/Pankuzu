import SwiftUI

import DokoSchema

struct LocationRow: View {
  let location: Location

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(String(format: "%.5f, %.5f", location.latitude, location.longitude))
        if let name = location.name {
          Text("\(name)")
        }
        if let street = location.street {
          Text("\(street)")
        }
        if let city = location.city, let stateProv = location.stateProv {
          Text("\(city), \(stateProv)")
        }
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seedPreviews()
  }
  @FetchAll var locations: [Location]
  NavigationStack {
    List {
      LocationRow(
        location: locations[1]
      )
    }
    .listStyle(.plain)
    .preferredColorScheme(.dark)
  }
}
