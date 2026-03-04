import SwiftUI
import Charts

import DokoSchema

struct PowerBin: Identifiable {
  let id: Int
  let timestamp: Date
  let power_kW: Double
}

@MainActor
@Observable
public final class ChargeDetailPowerChartModel {
  var charge: Charge

  @ObservationIgnored
  @FetchOne(ChargeHistory.none) var chargeHistory

  var powerBins: [PowerBin] = []
  var selectedBin: PowerBin?
  var maxPower: Double = 0

  public init(
    charge: Charge
  ) {
    self.charge = charge
    _chargeHistory = FetchOne(ChargeHistory.find(charge.id))

    guard let chargeHistory else { return }

    powerBins = createPowerBins(from: chargeHistory.batteryPower, numberOfBins: 80)

    var maxValue: Double = 0
    for bin in powerBins {
      maxValue = max(maxValue, bin.power_kW)
    }
    maxPower = ceil(maxValue)
  }

  private func createPowerBins(from data: [DokoDataPoint], numberOfBins: Int) -> [PowerBin] {
    guard !data.isEmpty,
          let first = data.first,
          let last = data.last else { return [] }

    let startTime = first.timestamp.timeIntervalSince1970
    let endTime = last.timestamp.timeIntervalSince1970
    let binDuration = (endTime - startTime) / Double(numberOfBins)

    var bins: [PowerBin] = []
    var previousPower: Double = first.datapoint

    for i in 0..<numberOfBins {
      let binStart = startTime + Double(i) * binDuration
      let binEnd = binStart + binDuration
      let binCenter = binStart + binDuration / 2

      let pointsInBin = data.filter { point in
        let t = point.timestamp.timeIntervalSince1970
        return t >= binStart && t < binEnd
      }

      let meanPower: Double
      if pointsInBin.isEmpty {
        meanPower = previousPower
      } else {
        meanPower = pointsInBin.map(\.datapoint).reduce(0, +) / Double(pointsInBin.count)
        previousPower = meanPower
      }

      bins.append(PowerBin(
        id: i,
        timestamp: Date(timeIntervalSince1970: binCenter),
        power_kW: meanPower
      ))
    }

    return bins
  }
}

public struct ChargeDetailPowerChartView: View {
  @Bindable var model: ChargeDetailPowerChartModel

  @Environment(\.dismiss) var dismiss

  public var body: some View {
    VStack {
      Chart {
        ForEach(model.powerBins) { bin in
          BarMark(
            x: .value("Time", bin.timestamp),
            y: .value("Power", bin.power_kW),
            width: .fixed(3)
          )
          .foregroundStyle(.green)
        }

        if let selected = model.selectedBin {
          RuleMark(x: .value("time", selected.timestamp))
            .foregroundStyle(.gray.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

          PointMark(
            x: .value("time", selected.timestamp),
            y: .value("power", selected.power_kW)
          )
          .foregroundStyle(.green)
          .symbolSize(100)
          .annotation(position: .top) {
            VStack(spacing: 2) {
              Text(selected.timestamp, style: .time)
                .font(.caption2)
              Text(String(format: "%.1f kW", selected.power_kW))
                .font(.caption)
                .fontWeight(.semibold)
            }
            .padding(6)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(6)
          }
        }
      }
      .chartYScale(domain: 0...model.maxPower)
      .chartYAxis {
        AxisMarks(position: .trailing) { value in
          if let kw = value.as(Double.self) {
            AxisGridLine()
            AxisTick()
            AxisValueLabel(String(format: "%.0f kW", kw))
          }
        }
      }
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

                  let closest = model.powerBins.min { a, b in
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
      .padding()
    }
    .navigationTitle(Text("Charger Power"))
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
  @FetchAll var charges: [Charge]
  NavigationStack {
    ChargeDetailView(
      model: ChargeDetailModel(
        destination: .powerChart,
        chargeID: charges.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
