import SwiftUI
import Charts

import DokoExtensions
import DokoSharing
import DokoSchema
import CommonUI

@MainActor
@Observable
public final class TripDetailBatteryTemperatureModel {
  var trip: Trip

  @ObservationIgnored @FetchOne(TripData.none) var tripData
  @ObservationIgnored @Shared(.appSettings) var appSettings

  var batteryTemp: [DokoDataPoint] = []
  var minTemp: Measurement<UnitTemperature> = .init(value: 0, unit: .celsius)
  var maxTemp: Measurement<UnitTemperature> = .init(value: 60, unit: .celsius)
  var selectedPoint: DokoDataPoint?

  public init(trip: Trip) {
    self.trip = trip
    _tripData = FetchOne(TripData.find(trip.id))

    guard let tripData else { return }
    batteryTemp = downsample(tripData.batteryTemp, maxPoints: 60)

    let values = batteryTemp.map { converted($0.datapoint) }
    self.minTemp = Measurement(value: min(minTemp.value, floor((values.min() ?? 0) - 2)), unit: UnitTemperature.celsius)
      .converted(to: appSettings.metric ? .celsius : .fahrenheit)
    self.maxTemp = Measurement(value: max(maxTemp.value, ceil((values.max() ?? 0) + 2)), unit: UnitTemperature.celsius)
      .converted(to: appSettings.metric ? .celsius : .fahrenheit)
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

  var unit: UnitTemperature { appSettings.metric ? .celsius : .fahrenheit }

  func converted(_ celsius: Double) -> Double {
    Measurement(value: celsius, unit: UnitTemperature.celsius)
      .converted(to: unit).value
  }
}

public struct TripDetailBatteryTemperatureView: View {
  @Bindable var model: TripDetailBatteryTemperatureModel

  @Environment(\.dismiss) var dismiss

  public init(model: TripDetailBatteryTemperatureModel) {
    self.model = model
  }

  public var body: some View {
    VStack {
      if model.batteryTemp.isEmpty {
        ContentUnavailableView(
          "No Data",
          systemImage: "batteryblock.stack",
          description: Text("No battery temperature data was recorded for this trip.")
        )
      } else {
        Chart {
          ForEach(model.batteryTemp) { point in
            LineMark(
              x: .value("Time", point.timestamp),
              y: .value("Temp", model.converted(point.datapoint))
            )
            .foregroundStyle(DesignTokens.Color.batteryTemperature)
            .interpolationMethod(.monotone)
          }

          if let selected = model.selectedPoint {
            RuleMark(x: .value("Time", selected.timestamp))
              .foregroundStyle(.gray.opacity(0.5))
              .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

            PointMark(
              x: .value("Time", selected.timestamp),
              y: .value("Temp", model.converted(selected.datapoint))
            )
            .foregroundStyle(DesignTokens.Color.batteryTemperature)
            .symbolSize(100)

            PointMark(
              x: .value("Time", selected.timestamp),
              y: .value("Temp", model.converted(selected.datapoint))
            )
            .foregroundStyle(.clear)
            .annotation(position: .top) {
              VStack(spacing: 2) {
                Text(selected.timestamp, style: .time)
                  .font(.caption2)
                Text(String(format: "%.1f %@", model.converted(selected.datapoint), model.minTemp.unit.symbol))
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundStyle(DesignTokens.Color.batteryTemperature)
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
        .chartYScale(domain: model.minTemp.value...model.maxTemp.value)
        .chartYAxis {
          AxisMarks(position: .trailing) { value in
            AxisValueLabel("\(value.as(Double.self)!.formatted()) \(model.minTemp.unit.symbol)")
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
                    model.selectedPoint = model.batteryTemp.min { a, b in
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
    .navigationTitle(Text("Battery Temperature"))
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
        destination: .batteryTemperatureChart,
        tripID: trips.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
