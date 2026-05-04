import SwiftUI
import MapKit

import Sharing
import DokoSharing
import DokoSchema
import DokoTypes

@MainActor
@Observable
public final class ChargeDetailMapModel {
  var charge: Charge

  var coordinateRegion: MKCoordinateRegion = MKCoordinateRegion()

  public init(
    charge: Charge
  ) {
    self.charge = charge
    let mapCenter = CLLocationCoordinate2D(
      latitude: charge.latitude,
      longitude: charge.longitude
    )
    let mapSpan = MKCoordinateSpan(
      latitudeDelta: 0.01,
      longitudeDelta: 0.01
    )
    self.coordinateRegion = MKCoordinateRegion(center: mapCenter, span: mapSpan)
  }
}

public struct ChargeDetailMapView: View {
  @Bindable var model: ChargeDetailMapModel

  @State var mapCameraPosition: MapCameraPosition
  @State var showStylePicker = false

  @Shared(.appSettings) var appSettings
  @Environment(\.dismiss) var dismiss

  public init(
    model: ChargeDetailMapModel
  ) {
    self.model = model
    self.mapCameraPosition = .region(model.coordinateRegion)
  }

  public var body: some View {
    VStack {
      Map(
        position: $mapCameraPosition
      ) {
        Marker(
          "",
          systemImage: model.charge.chargerType == .ac ? "powerplug" : "ev.charger",
          coordinate: CLLocationCoordinate2D(
            latitude: model.charge.latitude,
            longitude: model.charge.longitude
          )
        )
        .tint(.indigo)
      }
      .mapStyle(appSettings.chargeMapStyle.mapStyle)
    }
    .confirmationDialog("Map Style", isPresented: $showStylePicker) {
      ForEach(DisplayMapStyle.allCases) { style in
        Button(style.name) { $appSettings.chargeMapStyle.withLock { $0 = style } }
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button { showStylePicker = true } label: {
          Image(systemName: "map")
        }
      }
      ToolbarItem {
        Button("Done") { dismiss() }
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  @FetchAll() var charges: [Charge]
  NavigationStack {
    ChargeDetailView(
      model: ChargeDetailModel(
        destination: .chargeLocationMap,
        chargeID: charges.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
