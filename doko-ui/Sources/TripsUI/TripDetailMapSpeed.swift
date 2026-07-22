import SwiftUI
import MapKit

import DokoSharing
import DokoSchema

public enum SpeedBin {
  case stopped
  case low
  case moderate
  case high

  public init(kilometersPerHour speed: Double, metric: Bool) {
    let value = metric ? speed : speed * 0.621371
    let thresholds = metric ? (20.0, 50.0, 100.0) : (15.0, 30.0, 60.0)
    switch value {
    case ..<thresholds.0: self = .stopped
    case ..<thresholds.1: self = .low
    case ..<thresholds.2: self = .moderate
    default: self = .high
    }
  }

  public var color: Color {
    switch self {
    case .stopped: return .red
    case .low: return .orange
    case .moderate: return .green
    case .high: return .blue
    }
  }
}

public struct SpeedSegment: Identifiable {
  public let id = UUID()
  public let start: CLLocationCoordinate2D
  public let end: CLLocationCoordinate2D
  public let speedKilometersPerHour: Double
}

@MainActor
@Observable
public final class TripDetailSpeedMapModel {
  var trip: Trip

  @ObservationIgnored @FetchOne(TripPosition.none) var tripPositions

  var positions: [VehiclePosition] = []
  var speedSegments: [SpeedSegment] = []
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
    self.positions = path
    self.speedSegments = zip(path, path.dropFirst()).map { start, end in
      SpeedSegment(
        start: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude),
        end: CLLocationCoordinate2D(latitude: end.latitude, longitude: end.longitude),
        speedKilometersPerHour: ((start.speed ?? 0) + (end.speed ?? 0)) / 2
      )
    }
  }
}

public struct TripDetailSpeedMapView: View {
  @Bindable var model: TripDetailSpeedMapModel

  @State var mapCameraPosition: MapCameraPosition
  @State var showStylePicker = false
  @State var currentCamera: MapCamera?

  @Shared(.appSettings) var appSettings
  @Environment(\.dismiss) var dismiss

  public init(
    model: TripDetailSpeedMapModel
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

        ForEach(model.speedSegments) { segment in
          MapPolyline(coordinates: [segment.start, segment.end])
            .stroke(
              SpeedBin(kilometersPerHour: segment.speedKilometersPerHour, metric: appSettings.metric).color,
              lineWidth: appSettings.tripMapStyle == .satellite ? 4 : 5
            )
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
        destination: .tripSpeedMap,
        tripID: tripID
      )
    )
    .preferredColorScheme(.dark)
  }
}
