import SwiftUI

import DokoSchema
import LocationsUI
import CommonUI

@MainActor
@Observable
final class LocationSettingsModel {
  @ObservationIgnored @FetchAll(
    Location
      .where { $0.isDeleted.eq(false) }  //      .where { $0.isHidden.eq(false) }
  ) var locations
}

struct LocationSettingsView: View {
  @Bindable var model: LocationSettingsModel

  @State var editLocation: Location.Draft?

  var body: some View {
    List {
      ForEach(model.locations.enumerated(), id: \.element.id) { index, location in
        LocationRow(location: location)
          .rowFormatter(index)
          .contentShape(Rectangle())
          .onTapGesture {
            editLocation = Location.Draft(location)
          }
      }
    }
    .listStyle(.plain)
    .sheet(item: $editLocation) { location in
      NavigationStack {
        LocationFormView(
          model: LocationFormModel(
            location: location
          )
        )
      }
      .presentationDetents([.medium])
    }
    .navigationTitle("Locations")
  }
}

#Preview {
  let _ = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    LocationSettingsView(
      model: LocationSettingsModel()
    )
    .preferredColorScheme(.dark)
  }
}
