import SwiftUI
import MapKit

import DokoSharing
import DokoSchema

@MainActor
@Observable
public final class TripDetailMapModel {
  var trip: Trip

  @ObservationIgnored @FetchOne(TripPosition.none) var tripPositions
  @ObservationIgnored @FetchOne(TripElevation.none) var tripElevations

  var tripPath: [CLLocationCoordinate2D] = []
  var elevationPath: [CLLocationCoordinate2D] = []
  var coordinateRegion: MKCoordinateRegion = MKCoordinateRegion()

  public init(
    trip: Trip
  ) {
    self.trip = trip
    _tripPositions = FetchOne(TripPosition.find(trip.id))
    guard let tripPositions else { return }

    let path = tripPositions.path
    let minLatitude = path.min(by: { $0.latitude < $1.latitude })?.latitude ?? min(trip.latitudeStart, trip.latitudeEnd)
    let maxLatitude = path.max(by: { $0.latitude < $1.latitude })?.latitude ?? max(trip.latitudeStart, trip.latitudeEnd)
    let minLongitude = path.min(by: { $0.longitude < $1.longitude })?.longitude ?? min(trip.longitudeStart, trip.longitudeEnd)
    let maxLongitude = path.max(by: { $0.longitude < $1.longitude })?.longitude ?? max(trip.longitudeStart, trip.longitudeEnd)
    let centerLatitude = (maxLatitude + minLatitude) / 2
    let centerLongitude = (maxLongitude + minLongitude) / 2
    let mapCenter = CLLocationCoordinate2D(
      latitude: centerLatitude,
      longitude: centerLongitude
    )
    let mapSpan = MKCoordinateSpan(
      latitudeDelta: abs(maxLatitude - minLatitude) * 1.5,
      longitudeDelta: abs(maxLongitude - minLongitude) * 1.5
    )
    self.coordinateRegion = MKCoordinateRegion(center: mapCenter, span: mapSpan)
    self.tripPath = path.map { position in
      CLLocationCoordinate2D(
        latitude: position.latitude,
        longitude: position.longitude
      )
    }

    _tripElevations = FetchOne(TripElevation.find(trip.id))
    if let tripElevations, !path.isEmpty {
      self.elevationPath = tripElevations.elevations.compactMap { elevation in
        let closest = path.min { a, b in
          abs(a.timestamp.timeIntervalSince(elevation.timestamp)) <
          abs(b.timestamp.timeIntervalSince(elevation.timestamp))
        }
        guard let closest else { return nil }
        return CLLocationCoordinate2D(latitude: closest.latitude, longitude: closest.longitude)
      }
    }
  }
}

public struct TripDetailMapView: View {
  @Bindable var model: TripDetailMapModel

  @State var mapCameraPosition: MapCameraPosition
  @State var showStylePicker = false
  @State var currentCamera: MapCamera?

  @Shared(.appSettings) var appSettings
  @Environment(\.dismiss) var dismiss

  public init(
    model: TripDetailMapModel
  ) {
    self.model = model
    self.mapCameraPosition = .region(model.coordinateRegion)
  }

  private func toggle3D() {
    $appSettings.tripMap3D.withLock { $0.toggle() }
    let span = model.coordinateRegion.span
    let fallbackDistance = max(span.latitudeDelta, span.longitudeDelta) * 111_000 * (appSettings.tripMap3D ? 2.5 : 1.0)
    let base = currentCamera ?? MapCamera(
      centerCoordinate: model.coordinateRegion.center,
      distance: fallbackDistance,
      heading: 0,
      pitch: 0
    )
    withAnimation {
      mapCameraPosition = .camera(MapCamera(
        centerCoordinate: base.centerCoordinate,
        distance: base.distance,
        heading: base.heading,
        pitch: appSettings.tripMap3D ? 50 : 0
      ))
    }
  }

  public var body: some View {
    VStack {
      Map(
        position: $mapCameraPosition
      ) {
        Marker(
          "Start",
          systemImage: "car.fill",
          coordinate: CLLocationCoordinate2D(
            latitude: model.trip.latitudeStart,
            longitude: model.trip.longitudeStart
          )
        )
        .tint(.indigo)
        Marker(
          "End",
          systemImage: "car.fill",
          coordinate: CLLocationCoordinate2D(
            latitude: model.trip.latitudeEnd,
            longitude: model.trip.longitudeEnd
          )
        )
        .tint(.cyan)

        if appSettings.tripMapPolyline {
          MapPolyline(
            MKPolyline(
              coordinates: model.tripPath,
              count: model.tripPath.count
            )
          )
          .stroke(.blue, lineWidth: appSettings.tripMapStyle == .satellite ? 2 : 3)
        }
        
        if appSettings.showPositionOnPath {
          ForEach(Array(model.tripPath.enumerated()), id: \.offset) { _, coord in
            Annotation("", coordinate: coord) {
              Circle()
                .fill(Color.blue)
                .frame(width: 6, height: 6)
            }
          }
        }

        if appSettings.showElevationOnPath {
          ForEach(Array(model.elevationPath.enumerated()), id: \.offset) { _, coord in
            Annotation("", coordinate: coord) {
              Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
            }
          }
        }
      }
      .mapStyle(appSettings.tripMapStyle.mapStyle)
      .onMapCameraChange(frequency: .continuous) { context in currentCamera = context.camera }
      .task {
        try? await Task.sleep(for: .seconds(0.25))
        let center = model.coordinateRegion.center
        let nudged = CLLocationCoordinate2D(
          latitude: center.latitude + 0.000001,
          longitude: center.longitude
        )
        if let cam = currentCamera {
          mapCameraPosition = .camera(MapCamera(
            centerCoordinate: nudged,
            distance: cam.distance,
            heading: cam.heading,
            pitch: cam.pitch
          ))
        } else {
          var region = model.coordinateRegion
          region.center = nudged
          mapCameraPosition = .region(region)
        }
      }
      .onAppear {
        guard appSettings.tripMap3D else { return }
        let span = model.coordinateRegion.span
        let distance = max(span.latitudeDelta, span.longitudeDelta) * 111_000 * 2.5
        mapCameraPosition = .camera(MapCamera(
          centerCoordinate: model.coordinateRegion.center,
          distance: distance,
          heading: 0,
          pitch: 50
        ))
      }
    }
    .confirmationDialog("Map Style", isPresented: $showStylePicker) {
      ForEach(DisplayMapStyle.allCases) { style in
        Button(style.name) { $appSettings.tripMapStyle.withLock { $0 = style } }
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button { showStylePicker = true } label: {
          Image(systemName: appSettings.tripMapStyle == .satellite ? "globe" : "car")
        }
      }
      ToolbarItem(placement: .topBarLeading) {
        Button(appSettings.tripMap3D ? "2D" : "3D") { toggle3D() }
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
  struct PreviewTripsLoader {
    @FetchAll var trips: [Trip]
    init() { _trips = FetchAll() }
  }
  let loader = PreviewTripsLoader()
  let tripID = loader.trips.first?.id ?? Trip.ID()
  return NavigationStack {
    TripDetailView(
      model: TripDetailModel(
        destination: .tripMap,
        tripID: tripID
      )
    )
    .preferredColorScheme(.dark)
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  struct PreviewTripsLoader {
    @FetchAll var trips: [Trip]
    init() { _trips = FetchAll() }
  }
  let loader = PreviewTripsLoader()
  @Shared(.appSettings) var appSettings
  $appSettings.tripMapPolyline.withLock { $0 = false }
  $appSettings.showElevationOnPath.withLock { $0 = true }
  let tripID = loader.trips.first?.id ?? Trip.ID()
  return NavigationStack {
    TripDetailView(
      model: TripDetailModel(
        destination: .tripMap,
        tripID: tripID
      )
    )
    .preferredColorScheme(.dark)
  }
}

