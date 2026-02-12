import SwiftUI
import MapKit

import CommonUI
import DokoSharing
import DokoSchema

@MainActor
@Observable
public final class LocationFormModel: Identifiable {
  var location: Location.Draft
  let unmodifiedLocation: Location.Draft

  var isDismissed = false
  var saveErrorMessage: String?
  var isSaveErrorPresented = false

  @ObservationIgnored
  @Dependency(\.defaultDatabase) var database

  public init(
    location: Location.Draft
  ) {
    self.location = location
    self.unmodifiedLocation = location
  }

  var unchanged: Bool {
    return location == unmodifiedLocation
  }

  func cancelButtonTapped() {
    isDismissed = true
  }

  func saveButtonTapped() {
    do {
      try database.write { db in
        let _ =
        try Location
          .upsert { location }
          .returning(\.id)
          .fetchOne(db)
      }
    } catch {
      reportIssue(error)
      isDismissed = true
    }
    isDismissed = true
  }
}

public struct LocationFormView: View {
  @Environment(\.dismiss) var dismiss

  @Bindable var model: LocationFormModel

  @State var selectedMapItem: MKMapItem?
  @State var mapItems: [MKMapItem] = []

  @Shared(.poiThreshold) var poiThreshold

  public init(model: LocationFormModel) {
    self.model = model
  }

  public var body: some View {
    Form {
      Section {
        TextField(
          "Name",
          text: Binding(
            get: { model.location.name ?? "" },
            set: { model.location.name = $0.isEmpty ? nil : $0 }
          )
        )
        TextField(
          "Address",
          text: Binding(
            get: { model.location.street ?? "" },
            set: { model.location.street = $0.isEmpty ? nil : $0 }
          )
        )
        TextField(
          "City",
          text: Binding(
            get: { model.location.city ?? "" },
            set: { model.location.city = $0.isEmpty ? nil : $0 }
          )
        )
        TextField(
          "State/Prov",
          text: Binding(
            get: { model.location.stateProv ?? "" },
            set: { model.location.stateProv = $0.isEmpty ? nil : $0 }
          )
        )
      }
      header: {
        Text("Location Info")
      }

      Section {
        VStack {
          Picker("", selection: $selectedMapItem) {
            Text(model.unmodifiedLocation.name ?? "No nearby POI").tag(nil as MKMapItem?)
            ForEach(mapItems) { item in
              if let name = item.name {
                Text(name).tag(item as MKMapItem?)
              }
            }
          }
          .pickerStyle(.menu)
        }
      } header: {
        Text("Nearby Points of Interest")
      }
    }
    .onChange(of: selectedMapItem) {
      model.location.name = selectedMapItem?.name ?? model.unmodifiedLocation.name ?? "Unknown location"
    }
    .onChange(of: model.isDismissed) {
      dismiss()
    }
    .task(id: poiThreshold) {
      let latitude = model.location.latitude
      let longitude = model.location.longitude
      do {
        let localSearch = MKLocalSearch(
          request: MKLocalPointsOfInterestRequest(
            center: CLLocationCoordinate2D(
              latitude: latitude,
              longitude: longitude
            ),
            radius: poiThreshold
          )
        )
        let response = try await localSearch.start()
        mapItems = response.mapItems
      } catch {
        mapItems = []
      }
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
    ) { _ in
    } message: { message in
      Text(message)
    }
  }
}

 #Preview {
   let _ = prepareDependencies {
     try! $0.bootstrapDatabase()
     try! $0.defaultDatabase.seedPreviews()
   }
   @FetchAll() var locations: [Location]
   NavigationStack {
     LocationFormView(
       model: LocationFormModel(
         location: Location.Draft(locations[1])
       )
     )
     .preferredColorScheme(.dark)
     .navigationTitle("Location")
     .navigationBarTitleDisplayMode(.inline)
   }
 }
