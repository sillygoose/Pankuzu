import SwiftUI
import Charts

import DokoExtensions
import DokoSharing
import DokoSchema
import CommonUI

@MainActor
@Observable
public final class ChargeDetailBatteryTemperatureModel {
  var charge: Charge

  @ObservationIgnored @FetchOne(ChargeHistory.none) var chargeHistory
  @ObservationIgnored @Shared(.appSettings) var appSettings

  var batteryTemp: [DokoDataPoint] = []
  var couplerTemp: [DokoDataPoint] = []
  var minYAxis: Measurement<UnitTemperature> = .init(value: -5, unit: .celsius)
  var maxYAxis: Measurement<UnitTemperature> = .init(value: 62, unit: .celsius)
  var selectedPoint: DokoDataPoint?
  var selectedCouplerPoint: DokoDataPoint?

  public init(charge: Charge) {
    self.charge = charge
    _chargeHistory = FetchOne(ChargeHistory.find(charge.id))

    guard let chargeHistory else { return }
    batteryTemp = downsample(chargeHistory.batteryTemp, maxPoints: 60)
    couplerTemp = downsample(chargeHistory.couplerTemp, maxPoints: 60)

    let batteryValues = batteryTemp.map { $0.datapoint }
    let couplerValues = couplerTemp.map { $0.datapoint }
    let allValues = batteryValues + couplerValues
    let minY = floor(allValues.min() ?? 0) - 2
    let maxY = ceil(allValues.max() ?? 0) + 2
    self.minYAxis = Measurement(value: min(minYAxis.value, minY), unit: UnitTemperature.celsius)
      .converted(to: unit)
    self.maxYAxis = Measurement(value: max(maxYAxis.value, maxY), unit: UnitTemperature.celsius)
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

public struct ChargeDetailBatteryTemperatureView: View {
  @Bindable var model: ChargeDetailBatteryTemperatureModel

  @Environment(\.dismiss) var dismiss

  public init(model: ChargeDetailBatteryTemperatureModel) {
    self.model = model
  }

  public var body: some View {
    VStack {
      if model.batteryTemp.isEmpty {
        ContentUnavailableView(
          "No Data",
          systemImage: "batteryblock.stack",
          description: Text("No battery temperature data was recorded for this charge.")
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

          ForEach(model.couplerTemp) { point in
            LineMark(
              x: .value("Time", point.timestamp),
              y: .value("Temp", model.converted(point.datapoint))
            )
            .foregroundStyle(by: .value("Series", "Coupler"))
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
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
                Text(String(format: "%.0f %@", model.converted(selected.datapoint), model.minYAxis.unit.symbol))
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundStyle(DesignTokens.Color.batteryTemperature)
                if let coupler = model.selectedCouplerPoint {
                  Text(String(format: "%.0f %@", model.converted(coupler.datapoint), model.minYAxis.unit.symbol))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
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
          "Coupler": Color.orange
        ])
        .chartLegend(.hidden)
        .chartXScale(domain: model.charge.timeStart...model.charge.timeEnd)
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
                    model.selectedPoint = model.batteryTemp.min { a, b in
                      abs(a.timestamp.timeIntervalSince(timestamp)) < abs(b.timestamp.timeIntervalSince(timestamp))
                    }
                    model.selectedCouplerPoint = model.couplerTemp.min { a, b in
                      abs(a.timestamp.timeIntervalSince(timestamp)) < abs(b.timestamp.timeIntervalSince(timestamp))
                    }
                  }
                  .onEnded { _ in
                    model.selectedPoint = nil
                    model.selectedCouplerPoint = nil
                  }
              )
          }
        }
        .frame(width: 340, height: 300)
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
              .fill(Color.orange)
              .frame(width: 20, height: 2)
            Text("Coupler")
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
  @FetchAll var charges: [Charge]
  NavigationStack {
    ChargeDetailView(
      model: ChargeDetailModel(
        destination: .batteryTemperatureChart,
        chargeID: charges.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
