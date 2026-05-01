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
  var batteryEnergy: [DokoDataPoint] = []
  var minYAxis: Measurement<UnitPercent> = .init(value: 0, unit: .percent)
  var maxYAxis: Measurement<UnitPercent> = .init(value: 100, unit: .percent)
  var maxBatteryEnergy: Double = 1
  var selectedStateOfChargePoint: DokoDataPoint?
  var selectedEnergyPoint: DokoDataPoint?

  public init(trip: Trip) {
    self.trip = trip
    _tripData = FetchOne(TripData.find(trip.id))

    guard let tripData, !tripData.stateOfCharge.isEmpty else { return }
    stateOfCharge = downsample(tripData.stateOfCharge, maxPoints: 60)
    batteryEnergy = downsample(tripData.batteryEnergy, maxPoints: 60)
    if let min = batteryEnergy.map(\.datapoint).min() {
      maxBatteryEnergy = ceil(-min + 0.5)
    }
  }

  func normalizeBatteryEnergy(_ kWh: Double) -> Double {
    -kWh / maxBatteryEnergy * 100
  }

  func kWhFromNormalized(_ normalized: Double) -> Double {
    normalized / 100 * maxBatteryEnergy
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

public struct TripDetailStateOfChargeView: View {
  @Bindable var model: TripDetailStateOfChargeModel

  @Environment(\.dismiss) var dismiss

  public init(
    model: TripDetailStateOfChargeModel
  ) {
    self.model = model
  }

  @ChartContentBuilder
  private var socSeries: some ChartContent {
    ForEach(model.stateOfCharge) { point in
      LineMark(
        x: .value("Time", point.timestamp),
        y: .value("SoC", point.datapoint)
      )
      .foregroundStyle(by: .value("Series", "SoC"))
      .interpolationMethod(.monotone)
    }
  }

  @ChartContentBuilder
  private var batteryEnergySeries: some ChartContent {
    ForEach(model.batteryEnergy) { point in
      LineMark(
        x: .value("Time", point.timestamp),
        y: .value("SoC", model.normalizeBatteryEnergy(point.datapoint))
      )
      .foregroundStyle(by: .value("Series", "Energy"))
      .interpolationMethod(.monotone)
      .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
    }
  }

  @ChartContentBuilder
  private var selectionMarks: some ChartContent {
    if let selectedStateOfChargePoint = model.selectedStateOfChargePoint {
      RuleMark(x: .value("Time", selectedStateOfChargePoint.timestamp))
        .foregroundStyle(.gray.opacity(0.5))
        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

      PointMark(
        x: .value("Time", selectedStateOfChargePoint.timestamp),
        y: .value("SoC", selectedStateOfChargePoint.datapoint)
      )
      .foregroundStyle(DesignTokens.Color.stateOfCharge)
      .symbolSize(100)

      if let selectedEnergyPoint = model.selectedEnergyPoint {
        PointMark(
          x: .value("Time", selectedEnergyPoint.timestamp),
          y: .value("SoC", model.normalizeBatteryEnergy(selectedEnergyPoint.datapoint))
        )
        .foregroundStyle(DesignTokens.Color.energy)
        .symbolSize(100)
      }

      PointMark(
        x: .value("Time", selectedStateOfChargePoint.timestamp),
        y: .value("SoC", selectedStateOfChargePoint.datapoint)
      )
      .foregroundStyle(.clear)
      .annotation(position: .top) {
        selectionAnnotation(selected: selectedStateOfChargePoint)
      }
    }
  }

  private func selectionAnnotation(selected: DokoDataPoint) -> some View {
    VStack(spacing: 2) {
      Text(selected.timestamp, style: .time)
        .font(.caption2)
      Text(String(format: "%.1f", selected.datapoint) + model.minYAxis.unit.symbol)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(DesignTokens.Color.stateOfCharge)
      if let energyPoint = model.selectedEnergyPoint {
        Text(String(format: "%.2f kWh", -energyPoint.datapoint))
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(DesignTokens.Color.energy)
      }
    }
    .padding(6)
    .background(Color(.systemBackground).opacity(0.9))
    .cornerRadius(6)
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
          socSeries
          batteryEnergySeries
          selectionMarks
        }
        .chartForegroundStyleScale([
          "SoC": DesignTokens.Color.stateOfCharge,
          "Energy": DesignTokens.Color.energy
        ])
        .chartLegend(.hidden)
        .chartXScale(domain: model.trip.timeStart...model.trip.timeEnd)
        .chartXAxis {
          AxisMarks(values: .automatic)
        }
        .chartYScale(domain: model.minYAxis.value...model.maxYAxis.value)
        .chartYAxis {
          AxisMarks(position: .trailing) { value in
            AxisValueLabel("\(value.as(Double.self)!.formatted())%")
            AxisGridLine()
            AxisTick()
          }
          AxisMarks(position: .leading, values: [0, 25, 50, 75, 100] as [Double]) { value in
            if let v = value.as(Double.self) {
              let fmt = model.maxBatteryEnergy < 2.2 ? "%.1f kWh" : "%.0f kWh"
              AxisValueLabel(String(format: fmt, model.kWhFromNormalized(v)))
            }
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
                    model.selectedStateOfChargePoint = model.stateOfCharge.min { a, b in
                      abs(a.timestamp.timeIntervalSince(timestamp)) < abs(b.timestamp.timeIntervalSince(timestamp))
                    }
                    model.selectedEnergyPoint = model.batteryEnergy.min { a, b in
                      abs(a.timestamp.timeIntervalSince(timestamp)) < abs(b.timestamp.timeIntervalSince(timestamp))
                    }
                  }
                  .onEnded { _ in
                    model.selectedStateOfChargePoint = nil
                    model.selectedEnergyPoint = nil
                  }
              )
          }
        }
        .frame(width: 340, height: 300)
        .padding(.top, 20)

        HStack(spacing: 20) {
          HStack(spacing: 6) {
            Rectangle()
              .fill(DesignTokens.Color.stateOfCharge)
              .frame(width: 20, height: 2)
            Text("State of Charge")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          HStack(spacing: 6) {
            Rectangle()
              .fill(DesignTokens.Color.energy)
              .frame(width: 20, height: 2)
            Text("Energy Consumed")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .padding(.top, 8)
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
