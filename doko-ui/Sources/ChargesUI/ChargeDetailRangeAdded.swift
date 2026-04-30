import SwiftUI
import Charts

import DokoSharing
import DokoSchema
import CommonUI

@MainActor
@Observable
public final class ChargeDetailRangeAddedModel {
  var charge: Charge

  @ObservationIgnored @FetchOne(ChargeHistory.none) var chargeHistory
  @ObservationIgnored @Shared(.appSettings) var appSettings

  var distanceToEmpty: [DokoDataPoint] = []
  var minYAxis: Double = 0
  var maxYAxis: Double = 1
  var selectedPoint: DokoDataPoint?

  public init(charge: Charge) {
    self.charge = charge
    _chargeHistory = FetchOne(ChargeHistory.find(charge.id))

    guard let chargeHistory, !chargeHistory.distanceToEmpty.isEmpty else { return }
    distanceToEmpty = downsample(chargeHistory.distanceToEmpty.map { convert($0) }, maxPoints: 60)
    minYAxis = floor((distanceToEmpty.map(\.datapoint).min() ?? 0) - 5)
    maxYAxis = ceil((distanceToEmpty.map(\.datapoint).max() ?? 1) + 5)
  }

  var unit: UnitLength { appSettings.metric ? .kilometers : .miles }

  private func convert(_ point: DokoDataPoint) -> DokoDataPoint {
    let converted = Measurement(value: point.datapoint, unit: UnitLength.kilometers)
      .converted(to: unit).value
    return DokoDataPoint(timestamp: point.timestamp, double: converted)
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

public struct ChargeDetailRangeAddedView: View {
  @Bindable var model: ChargeDetailRangeAddedModel

  @Environment(\.dismiss) var dismiss

  public init(model: ChargeDetailRangeAddedModel) {
    self.model = model
  }

  public var body: some View {
    VStack {
      if model.distanceToEmpty.isEmpty {
        ContentUnavailableView(
          "No Data",
          systemImage: "road.lanes.curved.right",
          description: Text("No range data was recorded for this charge.")
        )
      } else {
        Chart {
          ForEach(model.distanceToEmpty) { point in
            LineMark(
              x: .value("Time", point.timestamp),
              y: .value("Range", point.datapoint)
            )
            .foregroundStyle(DesignTokens.Color.rangeAdded)
            .interpolationMethod(.monotone)
          }

          if let selected = model.selectedPoint {
            RuleMark(x: .value("Time", selected.timestamp))
              .foregroundStyle(.gray.opacity(0.5))
              .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

            PointMark(
              x: .value("Time", selected.timestamp),
              y: .value("Range", selected.datapoint)
            )
            .foregroundStyle(DesignTokens.Color.rangeAdded)
            .symbolSize(100)

            PointMark(
              x: .value("Time", selected.timestamp),
              y: .value("Range", selected.datapoint)
            )
            .foregroundStyle(.clear)
            .annotation(position: .top) {
              VStack(spacing: 2) {
                Text(selected.timestamp, style: .time)
                  .font(.caption2)
                Text(String(format: "%.0f %@", selected.datapoint, model.unit.symbol))
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundStyle(DesignTokens.Color.rangeAdded)
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
        .chartYScale(domain: model.minYAxis...model.maxYAxis)
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
                    model.selectedPoint = model.distanceToEmpty.min { a, b in
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
    .navigationTitle(Text("Range Added"))
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
        destination: .rangeAddedChart,
        chargeID: charges.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
