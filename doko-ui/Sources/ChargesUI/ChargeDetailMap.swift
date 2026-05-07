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
      latitudeDelta: 0.0025,
      longitudeDelta: 0.0025
    )
    self.coordinateRegion = MKCoordinateRegion(center: mapCenter, span: mapSpan)
  }
}

public struct ChargeDetailMapView: View {
  @Bindable var model: ChargeDetailMapModel

  @State var mapCameraPosition: MapCameraPosition
  @State var showStylePicker = false
  @State var currentCamera: MapCamera?

  @Shared(.appSettings) var appSettings
  @Environment(\.dismiss) var dismiss

  public init(
    model: ChargeDetailMapModel
  ) {
    self.model = model
    self.mapCameraPosition = .region(model.coordinateRegion)
  }

  private func toggle3D() {
    $appSettings.chargeMap3D.withLock { $0.toggle() }
    let base = currentCamera ?? MapCamera(
      centerCoordinate: CLLocationCoordinate2D(latitude: model.charge.latitude, longitude: model.charge.longitude),
      distance: 500,
      heading: 0,
      pitch: appSettings.chargeMap3D ? 50 : 0
    )
    withAnimation {
      mapCameraPosition = .camera(MapCamera(
        centerCoordinate: base.centerCoordinate,
        distance: base.distance,
        heading: base.heading,
        pitch: appSettings.chargeMap3D ? 50 : 0
      ))
    }
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
      .onMapCameraChange(frequency: .continuous) { context in currentCamera = context.camera }
      .onAppear {
        guard appSettings.chargeMap3D else { return }
        mapCameraPosition = .camera(MapCamera(
          centerCoordinate: CLLocationCoordinate2D(latitude: model.charge.latitude, longitude: model.charge.longitude),
          distance: 500,
          heading: 0,
          pitch: 50
        ))
      }
    }
    .confirmationDialog("Map Style", isPresented: $showStylePicker) {
      ForEach(DisplayMapStyle.allCases) { style in
        Button(style.name) { $appSettings.chargeMapStyle.withLock { $0 = style } }
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button { showStylePicker = true } label: {
          Image(systemName: appSettings.chargeMapStyle == .satellite ? "globe" : "car")
        }
      }
      if appSettings.chargeMapStyle == .satellite {
        ToolbarItem(placement: .topBarLeading) {
          Button(appSettings.chargeMap3D ? "2D" : "3D") { toggle3D() }
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
