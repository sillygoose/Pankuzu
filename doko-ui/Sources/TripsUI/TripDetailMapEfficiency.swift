import SwiftUI
import MapKit

import DokoSharing
import DokoSchema

// Traffic-light gradient: red (worst efficiency) through yellow to green (best efficiency).
// Segments with energyKilowattHours <= 0 (net regen) are clamped to the green end, since
// their km/kWh is undefined/unbounded rather than merely large.
private enum EfficiencyScale {
  private static let stops: [(location: Double, red: Double, green: Double, blue: Double)] = [
    (0.00, 0.86, 0.15, 0.15),  // red
    (0.25, 0.95, 0.55, 0.10),  // orange
    (0.50, 0.95, 0.80, 0.15),  // yellow
    (0.75, 0.60, 0.80, 0.15),  // lime
    (1.00, 0.20, 0.70, 0.25),  // green
  ]

  static let domainMaxKilometersPerKilowattHour: Double = 10

  static func maxValue(metric: Bool) -> Double {
    metric ? domainMaxKilometersPerKilowattHour : domainMaxKilometersPerKilowattHour * 0.621371
  }

  static func color(kilometersPerKilowattHour value: Double) -> Color {
    color(fraction: value / domainMaxKilometersPerKilowattHour)
  }

  private static func color(fraction: Double) -> Color {
    let clamped = max(0.0, min(1.0, fraction))
    guard let upperIndex = stops.firstIndex(where: { $0.location >= clamped }), upperIndex > 0 else {
      let edge = clamped <= 0 ? stops[0] : stops[stops.count - 1]
      return Color(red: edge.red, green: edge.green, blue: edge.blue)
    }
    let lower = stops[upperIndex - 1]
    let upper = stops[upperIndex]
    let f = (clamped - lower.location) / (upper.location - lower.location)
    return Color(
      red: lower.red + (upper.red - lower.red) * f,
      green: lower.green + (upper.green - lower.green) * f,
      blue: lower.blue + (upper.blue - lower.blue) * f
    )
  }

  static var legendGradientColors: [Color] {
    stride(from: 0.0, through: 1.0, by: 1.0 / 16.0).map { color(fraction: $0) }
  }
}

private struct EfficiencySegment: Identifiable {
  let id = UUID()
  let coordinates: [CLLocationCoordinate2D]
  let distance: Double
  let energy: Double
  let efficiency: Double

  init(coordinates: [CLLocationCoordinate2D], distanceKilometers: Double, energyKilowattHours: Double) {
    self.coordinates = coordinates
    self.distance = distanceKilometers
    self.energy = energyKilowattHours
    let colorMapEfficiency: Double = {
      guard energyKilowattHours > 0 else { return EfficiencyScale.domainMaxKilometersPerKilowattHour }
      return min(distanceKilometers / energyKilowattHours, EfficiencyScale.domainMaxKilometersPerKilowattHour)
    }()
    self.efficiency = colorMapEfficiency
  }
  var description: String {
    "\(coordinates.count) points, \(String(format: "%.3f", distance)) km, \(String(format: "%.3f", energy)) kWh, \(String(format: "%.3f", efficiency)) km/kWh"
  }
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

    // distance/batteryEnergy are appended together, once per postTripData call (see
    // PostTripData.swift), so they're index-aligned pairwise. Trips recorded before that was
    // true can still have mismatched lengths, so this trims to the shorter of the two rather
    // than assuming equal counts.
    let distancePoints = tripData.distance
    let energyPoints = tripData.batteryEnergy
    let pairCount = min(distancePoints.count, energyPoints.count)

    struct EfficiencyWindow {
      let start: Date
      let end: Date
      let distanceKilometers: Double
      let energyKilowattHours: Double
    }
    let efficiencyWindows: [EfficiencyWindow] = (0..<max(0, pairCount - 1)).map { i in
      EfficiencyWindow(
        start: distancePoints[i].timestamp,
        end: distancePoints[i + 1].timestamp,
        distanceKilometers: distancePoints[i + 1].datapoint - distancePoints[i].datapoint,
        energyKilowattHours: energyPoints[i].datapoint - energyPoints[i + 1].datapoint
      )
    }
    func efficiencyWindow(covering timestamp: Date) -> EfficiencyWindow? {
      efficiencyWindows.first { $0.start <= timestamp && timestamp <= $0.end }
        ?? efficiencyWindows.min { abs($0.start.timeIntervalSince(timestamp)) < abs($1.start.timeIntervalSince(timestamp)) }
    }

    // Geometry always comes from the recorded path itself (one segment per adjacent GPS point,
    // so the line follows the actual driven route with no gaps); only the color is looked up
    // from the coarser distance/energy windows above.
    self.efficiencySegments = (0..<(path.count - 1)).compactMap { i in
      guard let window = efficiencyWindow(covering: path[i].timestamp) else { return nil }
      return EfficiencySegment(
        coordinates: [
          CLLocationCoordinate2D(latitude: path[i].latitude, longitude: path[i].longitude),
          CLLocationCoordinate2D(latitude: path[i + 1].latitude, longitude: path[i + 1].longitude),
        ],
        distanceKilometers: window.distanceKilometers,
        energyKilowattHours: window.energyKilowattHours
      )
    }
//    for segment in self.efficiencySegments {
//      print(segment.description)
//    }
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
          MapPolyline(coordinates: segment.coordinates)
            .stroke(
              EfficiencyScale.color(kilometersPerKilowattHour: segment.efficiency),
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
        let unit = appSettings.metric ? "km/kWh" : "mi/kWh"
        let maxValue = EfficiencyScale.maxValue(metric: appSettings.metric)
        let ticks = Array(stride(from: 0.0, through: maxValue, by: maxValue / 4.0))
        VStack(alignment: .leading, spacing: 4) {
          Text("Efficiency (\(unit))")
            .font(.caption2)
            .foregroundStyle(.secondary)
          LinearGradient(
            colors: EfficiencyScale.legendGradientColors,
            startPoint: .leading,
            endPoint: .trailing
          )
          .containerRelativeFrame(.horizontal) { width, _ in width * 0.75 }
          .frame(height: 8)
          .clipShape(Capsule())
          HStack(spacing: 0) {
            ForEach(Array(ticks.enumerated()), id: \.offset) { index, tick in
              Text(String(format: "%.1f", tick))
                .font(.caption2)
              if index != ticks.count - 1 { Spacer() }
            }
          }
          .containerRelativeFrame(.horizontal) { width, _ in width * 0.75 }
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
        destination: .tripEfficiencyMap,
        tripID: tripID
      )
    )
    .preferredColorScheme(.dark)
  }
}
