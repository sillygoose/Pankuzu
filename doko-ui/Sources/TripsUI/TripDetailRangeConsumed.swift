import SwiftUI
import Charts

import DokoSharing
import DokoSchema
import CommonUI

@MainActor
@Observable
public final class TripDetailRangeEfficiencyModel {
  var trip: Trip

  @ObservationIgnored @FetchOne(TripData.none) var tripData
  @ObservationIgnored @Shared(.appSettings) var appSettings

  var distanceDriven: [DokoDataPoint] = []
  var rangeConsumed: [DokoDataPoint] = []
  var maxYAxis: Double = 1
  var selectedDistancePoint: DokoDataPoint?
  var selectedRangePoint: DokoDataPoint?

  public init(trip: Trip) {
    self.trip = trip
    _tripData = FetchOne(TripData.find(trip.id))

    guard let tripData, !tripData.odometer.isEmpty, !tripData.distanceToEmpty.isEmpty else { return }

    let odometerRaw = tripData.odometer
    let dteRaw = tripData.distanceToEmpty

    let odometerStart = odometerRaw.first?.datapoint ?? 0
    let dteStart = dteRaw.first?.datapoint ?? 0

    distanceDriven = downsample(odometerRaw.map { point in
      DokoDataPoint(timestamp: point.timestamp, double: convertKm(point.datapoint - odometerStart))
    }, maxPoints: 60)

    rangeConsumed = downsample(dteRaw.map { point in
      DokoDataPoint(timestamp: point.timestamp, double: convertKm(dteStart - point.datapoint))
    }, maxPoints: 60)

    let allValues = distanceDriven.map(\.datapoint) + rangeConsumed.map(\.datapoint)
    maxYAxis = ceil((allValues.max() ?? 1) + 1)
  }

  var unit: UnitLength { appSettings.metric ? .kilometers : .miles }

  private func convertKm(_ km: Double) -> Double {
    Measurement(value: km, unit: UnitLength.kilometers).converted(to: unit).value
  }

  private func downsample(_ data: [DokoDataPoint], maxPoints: Int) -> [DokoDataPoint] {
    guard data.count > maxPoints,
          let first = data.first,
          let last = data.last else { return data }
    let startTime = first.timestamp.timeIntervalSince1970
    let endTime = last.timestamp.timeIntervalSince1970
    let timeStep = (endTime - startTime) / Double(maxPoints - 1)
    return (0..<maxPoints).map { i in
      let targetTime = startTime + Double(i) * timeStep
      return data.min { a, b in
        abs(a.timestamp.timeIntervalSince1970 - targetTime) < abs(b.timestamp.timeIntervalSince1970 - targetTime)
      } ?? first
    }
  }
}

public struct TripDetailRangeEfficiencyView: View {
  @Bindable var model: TripDetailRangeEfficiencyModel

  @Environment(\.dismiss) var dismiss

  public init(model: TripDetailRangeEfficiencyModel) {
    self.model = model
  }

  @ChartContentBuilder
  private var distanceDrivenSeries: some ChartContent {
    ForEach(model.distanceDriven) { point in
      LineMark(
        x: .value("Time", point.timestamp),
        y: .value("Distance", point.datapoint)
      )
      .foregroundStyle(by: .value("Series", "Distance Driven"))
      .interpolationMethod(.monotone)
    }
  }

  @ChartContentBuilder
  private var rangeConsumedSeries: some ChartContent {
    ForEach(model.rangeConsumed) { point in
      LineMark(
        x: .value("Time", point.timestamp),
        y: .value("Distance", point.datapoint)
      )
      .foregroundStyle(by: .value("Series", "Range Consumed"))
      .interpolationMethod(.monotone)
      .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
    }
  }

  @ChartContentBuilder
  private var selectionMarks: some ChartContent {
    if let selected = model.selectedDistancePoint {
      RuleMark(x: .value("Time", selected.timestamp))
        .foregroundStyle(.gray.opacity(0.5))
        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

      PointMark(
        x: .value("Time", selected.timestamp),
        y: .value("Distance", selected.datapoint)
      )
      .foregroundStyle(DesignTokens.Color.distance)
      .symbolSize(100)

      if let rangePoint = model.selectedRangePoint {
        PointMark(
          x: .value("Time", rangePoint.timestamp),
          y: .value("Distance", rangePoint.datapoint)
        )
        .foregroundStyle(DesignTokens.Color.rangeUnder)
        .symbolSize(100)
      }

      PointMark(
        x: .value("Time", selected.timestamp),
        y: .value("Distance", selected.datapoint)
      )
      .foregroundStyle(.clear)
      .annotation(position: .top) {
        selectionAnnotation(selected: selected)
      }
    }
  }

  private func selectionAnnotation(selected: DokoDataPoint) -> some View {
    VStack(spacing: 2) {
      Text(selected.timestamp, style: .time)
        .font(.caption2)
      Text(String(format: "%.1f %@", selected.datapoint, model.unit.symbol))
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(DesignTokens.Color.distance)
      if let rangePoint = model.selectedRangePoint {
        Text(String(format: "%.1f %@", rangePoint.datapoint, model.unit.symbol))
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(DesignTokens.Color.rangeUnder)
      }
    }
    .padding(6)
    .background(Color(.systemBackground).opacity(0.9))
    .cornerRadius(6)
  }

  public var body: some View {
    VStack {
      if model.distanceDriven.isEmpty {
        ContentUnavailableView(
          "No Data",
          systemImage: "road.lanes",
          description: Text("No range data was recorded for this trip.")
        )
      } else {
        Chart {
          distanceDrivenSeries
          rangeConsumedSeries
          selectionMarks
        }
        .chartForegroundStyleScale([
          "Distance Driven": DesignTokens.Color.distance,
          "Range Consumed": DesignTokens.Color.rangeUnder
        ])
        .chartLegend(.hidden)
        .chartXScale(domain: model.trip.timeStart...model.trip.timeEnd)
        .chartXAxis {
          AxisMarks(values: .automatic)
        }
        .chartYScale(domain: 0...model.maxYAxis)
        .chartYAxis {
          AxisMarks(position: .trailing) { value in
            AxisValueLabel("\(value.as(Double.self)!.formatted()) \(model.unit.symbol)")
            AxisGridLine()
            AxisTick()
          }
        }
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
                    model.selectedDistancePoint = model.distanceDriven.min { a, b in
                      abs(a.timestamp.timeIntervalSince(timestamp)) < abs(b.timestamp.timeIntervalSince(timestamp))
                    }
                    model.selectedRangePoint = model.rangeConsumed.min { a, b in
                      abs(a.timestamp.timeIntervalSince(timestamp)) < abs(b.timestamp.timeIntervalSince(timestamp))
                    }
                  }
                  .onEnded { _ in
                    model.selectedDistancePoint = nil
                    model.selectedRangePoint = nil
                  }
              )
          }
        }
        .frame(width: 340, height: 300)
        .padding(.top, 20)

        HStack(spacing: 20) {
          HStack(spacing: 6) {
            Rectangle()
              .fill(DesignTokens.Color.distance)
              .frame(width: 20, height: 2)
            Text("Distance Driven")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          HStack(spacing: 6) {
            Rectangle()
              .fill(DesignTokens.Color.rangeUnder)
              .frame(width: 20, height: 2)
            Text("Range Consumed")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.top, 8)
      }
      Spacer()
    }
    .navigationTitle(Text("Range Efficiency"))
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
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  @FetchAll var trips: [Trip]
  NavigationStack {
    TripDetailView(
      model: TripDetailModel(
        destination: .rangeEfficiencyChart,
        tripID: trips.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
