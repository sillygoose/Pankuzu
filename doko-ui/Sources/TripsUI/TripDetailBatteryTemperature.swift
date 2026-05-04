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
  @ObservationIgnored @FetchOne(TripWeather.none) var tripWeather
  @ObservationIgnored @Shared(.appSettings) var appSettings

  var batteryTemp: [DokoDataPoint] = []
  var weatherTemp: [DokoWeather] = []
  var minYAxis: Measurement<UnitTemperature> = .init(value: -5, unit: .celsius)
  var maxYAxis: Measurement<UnitTemperature> = .init(value: 62, unit: .celsius)
  var selectedBatteryPoint: DokoDataPoint?
  var selectedWeatherPoint: DokoWeather?

  public init(trip: Trip) {
    self.trip = trip
    _tripData = FetchOne(TripData.find(trip.id))
    _tripWeather = FetchOne(TripWeather.find(trip.id))

    guard let tripData else { return }
    batteryTemp = downsample(tripData.batteryTemp, maxPoints: 60)
    weatherTemp = tripWeather?.weather ?? []

    let batteryValues = batteryTemp.map { $0.datapoint }
    let weatherValues = weatherTemp.map { $0.temperature }
    let allValues = batteryValues + weatherValues
    self.minYAxis = Measurement(value: min(minYAxis.value, floor((allValues.min() ?? 0) - 2)), unit: UnitTemperature.celsius)
      .converted(to: unit)
    self.maxYAxis = Measurement(value: max(maxYAxis.value, ceil((allValues.max() ?? 0) + 2)), unit: UnitTemperature.celsius)
      .converted(to: unit)
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
            .foregroundStyle(by: .value("Series", "Battery"))
            .interpolationMethod(.monotone)
          }

          ForEach(model.weatherTemp) { point in
            LineMark(
              x: .value("Time", point.timestamp),
              y: .value("Temp", model.converted(point.temperature))
            )
            .foregroundStyle(by: .value("Series", "Outside"))
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
          }

          if let selected = model.selectedBatteryPoint {
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
                Text(String(format: "%.1f %@", model.converted(selected.datapoint), model.minYAxis.unit.symbol))
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundStyle(DesignTokens.Color.batteryTemperature)
                if let weather = model.selectedWeatherPoint {
                  Text(String(format: "%.1f %@", model.converted(weather.temperature), model.minYAxis.unit.symbol))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignTokens.Color.weather)
                }
              }
              .padding(6)
              .background(Color(.systemBackground).opacity(0.9))
              .cornerRadius(6)
            }
          }
        }
        .chartForegroundStyleScale([
          "Battery": DesignTokens.Color.batteryTemperature,
          "Outside": DesignTokens.Color.weather
        ])
        .chartLegend(.hidden)
        .chartXScale(domain: model.trip.timeStart...model.trip.timeEnd)
        .chartXAxis {
          AxisMarks(values: .automatic)
        }
        .chartYScale(domain: model.minYAxis.value...model.maxYAxis.value)
        .chartYAxis {
          AxisMarks(position: .trailing) { value in
            AxisValueLabel("\(value.as(Double.self)!.formatted()) \(model.minYAxis.unit.symbol)")
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
                    model.selectedBatteryPoint = model.batteryTemp.min { a, b in
                      abs(a.timestamp.timeIntervalSince(timestamp)) < abs(b.timestamp.timeIntervalSince(timestamp))
                    }
                    model.selectedWeatherPoint = model.weatherTemp.min { a, b in
                      abs(a.timestamp.timeIntervalSince(timestamp)) < abs(b.timestamp.timeIntervalSince(timestamp))
                    }
                  }
                  .onEnded { _ in
                    model.selectedBatteryPoint = nil
                    model.selectedWeatherPoint = nil
                  }
              )
          }
        }
        .frame( height: 300)
        .padding(.horizontal)
        .padding(.top, 20)

        HStack(spacing: 20) {
          HStack(spacing: 6) {
            Rectangle()
              .fill(DesignTokens.Color.batteryTemperature)
              .frame(width: 20, height: 2)
            Text("Battery")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          HStack(spacing: 6) {
            Rectangle()
              .fill(DesignTokens.Color.weather)
              .frame(width: 20, height: 2)
            Text("Outside")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.top, 8)
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
