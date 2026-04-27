import SwiftUI
import Charts

import DokoExtensions
import DokoSharing
import DokoSchema
import CommonUI

@MainActor
@Observable
public final class TripDetailStateOfChargeModel {
  var trip: Trip

  @ObservationIgnored @FetchOne(TripData.none) var tripData

  var stateOfCharge: [DokoDataPoint] = []
  var minSoC: Double = 0
  var maxSoC: Double = 100
  var selectedPoint: DokoDataPoint?

  public init(trip: Trip) {
    self.trip = trip
    _tripData = FetchOne(TripData.find(trip.id))

    guard let tripData, !tripData.stateOfCharge.isEmpty else { return }
    stateOfCharge = downsample(tripData.stateOfCharge, maxPoints: 60)

    let values = stateOfCharge.map(\.datapoint)
    minSoC = max(0, floor((values.min() ?? 0) - 2))
    maxSoC = min(100, ceil((values.max() ?? 100) + 2))
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

  func color(for soc: Double) -> Color {
    if soc < 25 { return .red }
    if soc < 50 { return .yellow }
    return .green
  }
}

public struct TripDetailStateOfChargeView: View {
  @Bindable var model: TripDetailStateOfChargeModel

  @Environment(\.dismiss) var dismiss

  public init(model: TripDetailStateOfChargeModel) {
    self.model = model
  }

  public var body: some View {
    VStack {
      if model.stateOfCharge.isEmpty {
        ContentUnavailableView(
          "No Data",
          systemImage: "battery.75percent",
          description: Text("No state of charge data was recorded for this trip.")
        )
      } else {
        Chart {
          ForEach(model.stateOfCharge) { point in
            LineMark(
              x: .value("Time", point.timestamp),
              y: .value("SoC", point.datapoint)
            )
            .foregroundStyle(DesignTokens.Color.stateOfCharge)
            .interpolationMethod(.monotone)
          }

          if let selected = model.selectedPoint {
            RuleMark(x: .value("Time", selected.timestamp))
              .foregroundStyle(.gray.opacity(0.5))
              .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

            PointMark(
              x: .value("Time", selected.timestamp),
              y: .value("SoC", selected.datapoint)
            )
            .foregroundStyle(model.color(for: selected.datapoint))
            .symbolSize(100)

            PointMark(
              x: .value("Time", selected.timestamp),
              y: .value("SoC", selected.datapoint)
            )
            .foregroundStyle(.clear)
            .annotation(position: .top) {
              VStack(spacing: 2) {
                Text(selected.timestamp, style: .time)
                  .font(.caption2)
                Text(String(format: "%.0f%%", selected.datapoint))
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundStyle(model.color(for: selected.datapoint))
              }
              .padding(6)
              .background(Color(.systemBackground).opacity(0.9))
              .cornerRadius(6)
            }
          }
        }
        .chartXScale(domain: model.trip.timeStart...model.trip.timeEnd)
        .chartXAxis {
          AxisMarks(values: .automatic)
        }
        .chartYScale(domain: model.minSoC...model.maxSoC)
        .chartYAxis {
          AxisMarks(position: .trailing) { value in
            AxisValueLabel("\(value.as(Double.self)!.formatted())%")
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
                    model.selectedPoint = model.stateOfCharge.min { a, b in
                      abs(a.timestamp.timeIntervalSince(timestamp)) < abs(b.timestamp.timeIntervalSince(timestamp))
                    }
                  }
                  .onEnded { _ in
                    model.selectedPoint = nil
                  }
              )
          }
        }
        .frame(width: 340, height: 300)
        .padding(.top, 20)
      }
      Spacer()
    }
    .navigationTitle(Text("State of Charge"))
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
        destination: .stateOfChargeChart,
        tripID: trips.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
