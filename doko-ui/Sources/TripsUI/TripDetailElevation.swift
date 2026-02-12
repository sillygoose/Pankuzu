import SwiftUI
import Charts

import Sharing

import DokoTypes
import DokoSchema

struct ElevationBin: Identifiable {
  let id: Int
  let timestamp: Date
  let elevation: Double
}

@MainActor
@Observable
public final class TripDetailElevationModel {
  var trip: Trip

  @ObservationIgnored
  @FetchOne(TripElevation.none) var tripElevations

  var elevationBins: [ElevationBin] = []
  var minimumElevation: Measurement<UnitLength> = .init(value: 0, unit: .meters)
  var maximumElevation: Measurement<UnitLength> = .init(value: 0, unit: .meters)
  var selectedBin: ElevationBin?

  @ObservationIgnored
  @Shared(.metric) var metric

  public init(
    trip: Trip
  ) {
    self.trip = trip
    _tripElevations = FetchOne(TripElevation.find(trip.id))
    guard let tripElevations else {
      return
    }

    self.elevationBins = createElevationBins(from: tripElevations.elevations, numberOfBins: 80)

    var minElevation: Double = .greatestFiniteMagnitude
    var maxElevation: Double = -.greatestFiniteMagnitude
    for bin in elevationBins {
      let elevation = Measurement(value: bin.elevation, unit: UnitLength.meters)
        .converted(to: metric ? .meters : .feet).value
      minElevation = min(minElevation, elevation)
      maxElevation = max(maxElevation, elevation)
    }
    self.minimumElevation = Measurement(
      value: roundDownToNearest(number: minElevation),
      unit: metric ? UnitLength.meters : UnitLength.feet
    )
    self.maximumElevation = Measurement(
      value: roundUpToNearest(number: maxElevation),
      unit: metric ? UnitLength.meters : UnitLength.feet
    )
  }

  private func roundUpToNearest(number: Double) -> Double {
    let step = metric ? 50.0 : 100.0
    return ceil(number / step) * step + step
  }

  private func roundDownToNearest(number: Double) -> Double {
    let step = metric ? 50.0 : 100.0
    return floor(number / step) * step - step
  }

  private func createElevationBins(from data: [VehicleElevation], numberOfBins: Int) -> [ElevationBin] {
    guard !data.isEmpty,
          let first = data.first,
          let last = data.last else { return [] }

    let startTime = first.timestamp.timeIntervalSince1970
    let endTime = last.timestamp.timeIntervalSince1970
    let binDuration = (endTime - startTime) / Double(numberOfBins)

    var bins: [ElevationBin] = []
    var previousElevation: Double = first.elevation

    for i in 0..<numberOfBins {
      let binStart = startTime + Double(i) * binDuration
      let binEnd = binStart + binDuration
      let binCenter = binStart + binDuration / 2

      // Find all positions in this bin
      let positionsInBin = data.filter { position in
        let t = position.timestamp.timeIntervalSince1970
        return t >= binStart && t < binEnd
      }

      let meanElevation: Double
      if positionsInBin.isEmpty {
        // Use previous bin's elevation if no data in this bin
        meanElevation = previousElevation
      } else {
        meanElevation = positionsInBin.map(\.elevation).reduce(0, +) / Double(positionsInBin.count)
        previousElevation = meanElevation
      }

      bins.append(ElevationBin(
        id: i,
        timestamp: Date(timeIntervalSince1970: binCenter),
        elevation: meanElevation
      ))
    }

    return bins
  }
}

public struct TripDetailElevationView: View {
  @Bindable var model: TripDetailElevationModel

  @Environment(\.dismiss) var dismiss

  public init(model: TripDetailElevationModel) {
    self.model = model
  }

  public var body: some View {
    VStack {
      Chart {
        ForEach(model.elevationBins) { bin in
          let elevation = Measurement(value: bin.elevation, unit: UnitLength.meters)
            .converted(to: model.metric ? .meters : .feet)
          BarMark(
            x: .value("Time", bin.timestamp),
            yStart: .value("Elevation Min", model.minimumElevation.value),
            yEnd: .value("Elevation", elevation.value),
            width: .fixed(3)
          )
          .foregroundStyle(.green)
        }

        if let selected = model.selectedBin {
          let elevation = Measurement(value: selected.elevation, unit: UnitLength.meters)
            .converted(to: model.metric ? .meters : .feet)

          RuleMark(x: .value("time", selected.timestamp))
            .foregroundStyle(.gray.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

          PointMark(
            x: .value("time", selected.timestamp),
            y: .value("elevation", elevation.value)
          )
          .foregroundStyle(.green)
          .symbolSize(100)
          .annotation(position: .top) {
            VStack(spacing: 2) {
              Text(selected.timestamp, style: .time)
                .font(.caption2)
              Text(elevation.formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(0)))))
                .font(.caption)
                .fontWeight(.semibold)
            }
            .padding(6)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(6)
          }
        }
      }
      .chartYScale(domain: model.minimumElevation.value...model.maximumElevation.value)
      .chartYAxis(.automatic)
      .chartXAxis(.automatic)
      .chartOverlay { proxy in
        GeometryReader { geometry in
          Rectangle()
            .fill(.clear)
            .contentShape(Rectangle())
            .gesture(
              DragGesture(minimumDistance: 0)
                .onChanged { value in
                  let x = value.location.x - geometry[proxy.plotFrame!].origin.x
                  guard let timestamp: Date = proxy.value(atX: x) else { return }

                  let closest = model.elevationBins.min { a, b in
                    abs(a.timestamp.timeIntervalSince(timestamp)) < abs(b.timestamp.timeIntervalSince(timestamp))
                  }
                  model.selectedBin = closest
                }
                .onEnded { _ in
                  model.selectedBin = nil
                }
            )
        }
      }
    }
    .padding()
    .navigationTitle(Text("Elevation Change"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button("Done") { dismiss() }
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try! $0.bootstrapDatabase()
    try! $0.defaultDatabase.seedPreviews()
  }
  @FetchAll var trips: [Trip]
  NavigationStack {
    TripDetailView(
      model: TripDetailModel(
        destination: .elevationChart,
        tripID: trips.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
