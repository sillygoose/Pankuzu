import SwiftUI
import MapKit

import DokoSharing
import DokoSchema

private enum SpeedScale {
  static let anchorColors: [Color] = [.red, .orange, .green, .blue]

  static func maxSpeed(metric: Bool) -> Double {
    metric ? 160.0 : 100.0
  }

  static func color(kilometersPerHour speed: Double, metric: Bool) -> Color {
    let value = metric ? speed : speed * 0.621371
    let max = maxSpeed(metric: metric)
    let step = max / Double(anchorColors.count - 1)
    let stops: [(value: Double, color: Color)] = anchorColors.enumerated().map { index, color in
      (Double(index) * step, color)
    }
    if value <= stops.first!.value { return stops.first!.color }
    if value >= stops.last!.value { return stops.last!.color }
    for i in 1..<stops.count {
      guard value <= stops[i].value else { continue }
      let lower = stops[i - 1]
      let upper = stops[i]
      let fraction = (value - lower.value) / (upper.value - lower.value)
      return lower.color.mix(with: upper.color, by: fraction)
    }
    return stops.last!.color
  }
}

private struct SpeedSegment: Identifiable {
  let id = UUID()
  let start: CLLocationCoordinate2D
  let end: CLLocationCoordinate2D
  let speedKilometersPerHour: Double
}

@MainActor
@Observable
public final class TripDetailSpeedMapModel {
  var trip: Trip

  @ObservationIgnored @FetchOne(TripPosition.none) var tripPositions

  fileprivate var speedSegments: [SpeedSegment] = []
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
              SpeedScale.color(kilometersPerHour: segment.speedKilometersPerHour, metric: appSettings.metric),
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
      .overlay(alignment: .bottomTrailing) {
        let unit = appSettings.metric ? "kph" : "mph"
        let maxSpeed = SpeedScale.maxSpeed(metric: appSettings.metric)
        let ticks = Array(stride(from: 0.0, through: maxSpeed, by: 20.0))
        let legendWidth: CGFloat = 200
        VStack(alignment: .leading, spacing: 4) {
          Text("Speed (\(unit))")
            .font(.caption2)
            .foregroundStyle(.secondary)
          LinearGradient(
            colors: SpeedScale.anchorColors,
            startPoint: .leading,
            endPoint: .trailing
          )
          .frame(width: legendWidth, height: 8)
          .clipShape(Capsule())
          HStack(spacing: 0) {
            ForEach(Array(ticks.enumerated()), id: \.offset) { index, tick in
              Text("\(Int(tick))")
                .font(.caption2)
              if index != ticks.count - 1 { Spacer() }
            }
          }
          .frame(width: legendWidth)
        }
        .fixedSize()
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding(12)
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
