import SwiftUI
import Charts

import DokoTypes
import DokoSharing
import DokoSchema
import CommonUI

@MainActor
@Observable
public final class TripDetailEnergyModel {
  var trip: Trip

  @ObservationIgnored
  @FetchOne(TripData.none) var tripData

  var energyToEmpty: [DokoDataPoint] = []
  var calculatedEnergy: [DokoDataPoint] = []

  var minEnergyToEmpty: Measurement<UnitEnergy> = .init(value: 0, unit: .kilowattHours)
  var maxEnergyToEmpty: Measurement<UnitEnergy> = .init(value: 0, unit: .kilowattHours)
  var useSecondsForXAxis: Bool = false
  var selectedPoint: DokoDataPoint?
  var selectedCalculatedPoint: DokoDataPoint?

  public init(
    trip: Trip
  ) {
    self.trip = trip
    _tripData = FetchOne(TripData.find(trip.id))

    let tripDuration = trip.timeEnd.timeIntervalSince(trip.timeStart)
    useSecondsForXAxis = tripDuration < 300

    guard let tripData else { return }
    energyToEmpty = downsample(tripData.energyToEmpty, maxPoints: 60)

    let initialEnergy = trip.energyToEmptyStart ?? 0.0
    let rawBatteryEnergy = tripData.batteryEnergy
    calculatedEnergy = rawBatteryEnergy.map { point in
      DokoDataPoint(timestamp: point.timestamp, double: initialEnergy + point.datapoint)
    }
    calculatedEnergy = downsample(calculatedEnergy, maxPoints: 60)
    guard !calculatedEnergy.isEmpty else { return }

    let datapoints = (energyToEmpty + calculatedEnergy).map(\.datapoint)
    let minEnergy = datapoints.min() ?? .greatestFiniteMagnitude
    let maxEnergy = datapoints.max() ?? -.greatestFiniteMagnitude
    minEnergyToEmpty = .init(value: floor(minEnergy), unit: .kilowattHours)
    maxEnergyToEmpty = .init(value: ceil(maxEnergy), unit: .kilowattHours)
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

public struct TripDetailEnergyView: View {
  @Bindable var model: TripDetailEnergyModel

  @Environment(\.dismiss) var dismiss

  public init(model: TripDetailEnergyModel) {
    self.model = model
  }

  public var body: some View {
    VStack {
      if model.energyToEmpty.isEmpty && model.calculatedEnergy.isEmpty {
        ContentUnavailableView(
          "No Energy Data",
          systemImage: "bolt.slash",
          description: Text("No energy data was recorded for this trip.")
        )
      } else {
      VStack {
        Chart {
          ForEach(model.energyToEmpty) { point in
            LineMark(
              x: .value("time", point.timestamp),
              y: .value("energy", point.datapoint),
              series: .value("series", "energyToEmpty")
            )
            .foregroundStyle(.red)
            .interpolationMethod(.monotone)
          }

          ForEach(model.calculatedEnergy) { point in
            LineMark(
              x: .value("time", point.timestamp),
              y: .value("energy", point.datapoint),
              series: .value("series", "batteryEnergy")
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.monotone)
          }

          if let selected = model.selectedPoint {
            RuleMark(x: .value("time", selected.timestamp))
              .foregroundStyle(.gray.opacity(0.5))
              .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

            PointMark(
              x: .value("time", selected.timestamp),
              y: .value("energy", selected.datapoint)
            )
            .foregroundStyle(.red)
            .symbolSize(100)

            if let calculatedPoint = model.selectedCalculatedPoint {
              PointMark(
                x: .value("time", calculatedPoint.timestamp),
                y: .value("energy", calculatedPoint.datapoint)
              )
              .foregroundStyle(.blue)
              .symbolSize(100)
            }

            PointMark(
              x: .value("time", selected.timestamp),
              y: .value("energy", selected.datapoint)
            )
            .foregroundStyle(.clear)
            .annotation(position: .top) {
              VStack(spacing: 2) {
                Text(selected.timestamp, style: .time)
                  .font(.caption2)
                HStack(spacing: 8) {
                  Text(String(format: "%.3f", selected.datapoint))
                    .foregroundStyle(.red)
                  if let calculatedPoint = model.selectedCalculatedPoint {
                    Text(String(format: "%.3f", calculatedPoint.datapoint))
                      .foregroundStyle(.blue)
                  }
                }
                .font(.caption)
                .fontWeight(.semibold)
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
        .chartYScale(domain: model.minEnergyToEmpty.value...model.maxEnergyToEmpty.value)
        .chartYAxis {
          AxisMarks(position: .trailing) { value in
            AxisValueLabel("\(value.as(Double.self)!.formatted()) kWh")
            AxisGridLine()
            AxisTick()
          }
        }
        .chartForegroundStyleScale([
          "energyToEmpty": .red,
          "batteryEnergy": .blue
        ])
        .chartLegend(position: .bottom) {
          HStack {
            HStack(spacing: 4) {
              Circle().fill(.red).frame(width: 8, height: 8)
              Text("Vehicle Energy To Empty")
                .foregroundStyle(.red)
            }
            Spacer()
            HStack(spacing: 4) {
              Circle().fill(.blue).frame(width: 8, height: 8)
              Text("Battery Energy Estimate")
                .foregroundStyle(.blue)
            }
          }
          .font(.caption)
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

                    model.selectedPoint = model.energyToEmpty.min { a, b in
                      abs(a.timestamp.timeIntervalSince(timestamp)) < abs(b.timestamp.timeIntervalSince(timestamp))
                    }
                    model.selectedCalculatedPoint = model.calculatedEnergy.min { a, b in
                      abs(a.timestamp.timeIntervalSince(timestamp)) < abs(b.timestamp.timeIntervalSince(timestamp))
                    }
                  }
                  .onEnded { _ in
                    model.selectedPoint = nil
                    model.selectedCalculatedPoint = nil
                  }
              )
          }
        }
        .frame(width: 340, height: 300)
        .padding(.top, 20)
      }
      } // else
      Spacer()
    }
    .navigationTitle(Text("Energy Consumed"))
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
        destination: .energyUsedChart,
        tripID: trips.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
