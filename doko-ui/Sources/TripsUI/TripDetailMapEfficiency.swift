import SwiftUI
import MapKit

import DokoSharing
import DokoSchema

private enum EfficiencyBin: CaseIterable, Hashable {
  case regen, power

  init(
    energyKilowattHours: Double
  ) {
    guard energyKilowattHours > 0 else {
      self = .regen
      return
    }
    self = .power
  }

  var color: Color {
    switch self {
    case .regen: return .green
    case .power: return .red
    }
  }

  var label: String {
    switch self {
    case .regen: return "Regen"
    case .power: return "Power"
    }
  }
}

private struct EfficiencySegment: Identifiable {
  let id = UUID()
  let start: CLLocationCoordinate2D
  let end: CLLocationCoordinate2D
  let distanceKilometers: Double
  let energyKilowattHours: Double
}

@MainActor
@Observable
public final class TripDetailEfficiencyMapModel {
  var trip: Trip

  @ObservationIgnored @FetchOne(TripPosition.none) var tripPositions
  @ObservationIgnored @FetchOne(TripData.none) var tripData

  fileprivate var efficiencySegments: [EfficiencySegment] = []
  var coordinateRegion: MKCoordinateRegion = MKCoordinateRegion()

  public init(
    trip: Trip
  ) {
    self.trip = trip
    _tripPositions = FetchOne(TripPosition.find(trip.id))
    guard let tripPositions else { return }
    _tripData = FetchOne(TripData.find(trip.id))
    guard let tripData else { return }

    let path = tripPositions.path
    guard path.count > 1 else { return }

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

    func nearest(_ points: [DokoDataPoint], to timestamp: Date) -> Double {
      points.min { abs($0.timestamp.timeIntervalSince(timestamp)) < abs($1.timestamp.timeIntervalSince(timestamp)) }?.datapoint ?? 0
    }
    let odometerAtPath = path.map { nearest(tripData.odometer, to: $0.timestamp) }
    let energyAtPath = path.map { nearest(tripData.batteryEnergy, to: $0.timestamp) }

    self.efficiencySegments = (0..<(path.count - 1)).map { i in
      EfficiencySegment(
        start: CLLocationCoordinate2D(latitude: path[i].latitude, longitude: path[i].longitude),
        end: CLLocationCoordinate2D(latitude: path[i + 1].latitude, longitude: path[i + 1].longitude),
        distanceKilometers: odometerAtPath[i + 1] - odometerAtPath[i],
        energyKilowattHours: energyAtPath[i] - energyAtPath[i + 1]
      )
    }
    print(self.efficiencySegments)
  }
}

public struct TripDetailEfficiencyMapView: View {
  @Bindable var model: TripDetailEfficiencyMapModel

  @State var mapCameraPosition: MapCameraPosition
  @State var showStylePicker = false
  @State var currentCamera: MapCamera?

  @Shared(.appSettings) var appSettings
  @Environment(\.dismiss) var dismiss

  public init(
    model: TripDetailEfficiencyMapModel
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
        
        ForEach(model.efficiencySegments) { segment in
          MapPolyline(coordinates: [segment.start, segment.end])
            .stroke(
              EfficiencyBin(energyKilowattHours: segment.energyKilowattHours).color,
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
        VStack(alignment: .leading, spacing: 4) {
          ForEach(EfficiencyBin.allCases, id: \.self) { bin in
            HStack(spacing: 6) {
              Circle()
                .fill(bin.color)
                .frame(width: 8, height: 8)
              Text(bin.label)
            }
          }
        }
        .font(.caption)
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
        destination: .tripEfficiencyMap,
        tripID: tripID
      )
    )
    .preferredColorScheme(.dark)
  }
}
