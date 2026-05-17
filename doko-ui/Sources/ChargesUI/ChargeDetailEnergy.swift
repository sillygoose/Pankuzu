import SwiftUI
import Charts

import DokoTypes
import DokoSharing
import DokoSchema
import CommonUI

@MainActor
@Observable
public final class ChargeDetailEnergyModel {
  var charge: Charge

  @ObservationIgnored @FetchOne(ChargeHistory.none) var chargeHistory

  var energyToEmpty: [DokoDataPoint] = []
  var calculatedEnergy: [DokoDataPoint] = []

  var minEnergy: Double = 0
  var maxEnergy: Double = 100
  var useSecondsForXAxis: Bool = false
  var selectedPoint: DokoDataPoint?
  var selectedCalculatedPoint: DokoDataPoint?

  public init(
    charge: Charge
  ) {
    self.charge = charge
    _chargeHistory = FetchOne(ChargeHistory.find(charge.id))

    let chargeDuration = charge.timeEnd.timeIntervalSince(charge.timeStart)
    useSecondsForXAxis = chargeDuration < 300

    guard let chargeHistory else { return }

    if chargeHistory.energyToEmpty.isEmpty {
      guard !chargeHistory.batteryEnergy.isEmpty else { return }
      calculatedEnergy = downsample(chargeHistory.batteryEnergy, maxPoints: 60)
      let datapoints = calculatedEnergy.map(\.datapoint)
      self.minEnergy = floor(datapoints.min() ?? 0)
      self.maxEnergy = ceil(datapoints.max() ?? 100)
      return
    }

    energyToEmpty = downsample(chargeHistory.energyToEmpty, maxPoints: 60)

    if let initialEnergy = charge.energyToEmptyStart {
      let rawBatteryEnergy = chargeHistory.batteryEnergy
      calculatedEnergy = rawBatteryEnergy.map { point in
        DokoDataPoint(timestamp: point.timestamp, double: initialEnergy + point.datapoint)
      }
      calculatedEnergy = downsample(calculatedEnergy, maxPoints: 60)
    }

    let datapoints = (energyToEmpty + calculatedEnergy).map(\.datapoint)
    let minValue = datapoints.min() ?? .greatestFiniteMagnitude
    let maxValue = datapoints.max() ?? -.greatestFiniteMagnitude
    self.minEnergy = floor(minValue)
    self.maxEnergy = ceil(maxValue)
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

public struct ChargeDetailEnergyView: View {
  @Bindable var model: ChargeDetailEnergyModel

  @Environment(\.dismiss) var dismiss

  public init(model: ChargeDetailEnergyModel) {
    self.model = model
  }

  public var body: some View {
    VStack {
      VStack {
        Chart {
          ForEach(model.energyToEmpty) { point in
            LineMark(
              x: .value("time", point.timestamp),
              y: .value("energy", point.datapoint),
              series: .value("series", "energyToEmpty")
            )
            .foregroundStyle(.green)
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

            if !model.energyToEmpty.isEmpty {
              PointMark(
                x: .value("time", selected.timestamp),
                y: .value("energy", selected.datapoint)
              )
              .foregroundStyle(.green)
              .symbolSize(100)
            }

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
                  if !model.energyToEmpty.isEmpty {
                    Text(String(format: "%.3f", selected.datapoint))
                      .foregroundStyle(.green)
                  }
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
        .chartXScale(domain: model.charge.timeStart...model.charge.timeEnd)
        .chartXAxis {
          AxisMarks(values: .automatic)
        }
        .chartYScale(domain: model.minEnergy...model.maxEnergy)
        .chartYAxis {
          AxisMarks(position: .trailing) { value in
            AxisValueLabel("\(value.as(Double.self)!.formatted()) kWh")
            AxisGridLine()
            AxisTick()
          }
        }
        .chartForegroundStyleScale([
          "energyToEmpty": .green,
          "batteryEnergy": .blue
        ])
        .chartLegend(position: .bottom) {
          HStack {
            if !model.energyToEmpty.isEmpty {
              HStack(spacing: 4) {
                Circle().fill(.green).frame(width: 8, height: 8)
                Text("Vehicle Energy To Empty")
                  .foregroundStyle(.green)
              }
            }
            if !model.energyToEmpty.isEmpty && !model.calculatedEnergy.isEmpty {
              Spacer()
            }
            if !model.calculatedEnergy.isEmpty {
              HStack(spacing: 4) {
                Circle().fill(.blue).frame(width: 8, height: 8)
                Text("Energy Added")
                  .foregroundStyle(.blue)
              }
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

                    let nearest: ([DokoDataPoint]) -> DokoDataPoint? = { points in
                      points.min { abs($0.timestamp.timeIntervalSince(timestamp)) < abs($1.timestamp.timeIntervalSince(timestamp)) }
                    }
                    model.selectedPoint = nearest(model.energyToEmpty) ?? nearest(model.calculatedEnergy)
                    model.selectedCalculatedPoint = nearest(model.calculatedEnergy)
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
      Spacer()
        .padding()
    }
    .navigationTitle(Text("Energy Added"))
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
  @FetchAll var charges: [Charge]
  NavigationStack {
    ChargeDetailView(
      model: ChargeDetailModel(
        destination: .energyAddedChart,
        chargeID: charges.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
