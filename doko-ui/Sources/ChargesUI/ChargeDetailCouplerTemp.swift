import SwiftUI
import Charts

import DokoSchema
import DokoSharing

struct CouplerTempBin: Identifiable {
  let id: Int
  let timestamp: Date
  let temp_C: Double
}

@MainActor
@Observable
final class ChargeDetailCouplerTempChartModel {
  var charge: Charge

  @ObservationIgnored
  @FetchOne(ChargeHistory.none) var chargeHistory

  @ObservationIgnored
  @Shared(.metric) var metric

  var tempBins: [CouplerTempBin] = []
  var selectedBin: CouplerTempBin?
  var maxTemp: Double = 0

  init(charge: Charge) {
    self.charge = charge
    _chargeHistory = FetchOne(ChargeHistory.find(charge.id))

    guard let chargeHistory else { return }

    tempBins = createTempBins(from: chargeHistory.couplerTemp, numberOfBins: 80)
    maxTemp = ceil(tempBins.map(\.temp_C).max() ?? 0)
  }

  private func createTempBins(from data: [DokoDataPoint], numberOfBins: Int) -> [CouplerTempBin] {
    guard !data.isEmpty,
          let first = data.first,
          let last = data.last else { return [] }

    let startTime = first.timestamp.timeIntervalSince1970
    let endTime = last.timestamp.timeIntervalSince1970
    let binDuration = (endTime - startTime) / Double(numberOfBins)

    var bins: [CouplerTempBin] = []
    var previousTemp: Double = first.datapoint

    for i in 0..<numberOfBins {
      let binStart = startTime + Double(i) * binDuration
      let binEnd = binStart + binDuration
      let binCenter = binStart + binDuration / 2

      let pointsInBin = data.filter { point in
        let t = point.timestamp.timeIntervalSince1970
        return t >= binStart && t < binEnd
      }

      let meanTemp: Double
      if pointsInBin.isEmpty {
        meanTemp = previousTemp
      } else {
        meanTemp = pointsInBin.map(\.datapoint).reduce(0, +) / Double(pointsInBin.count)
        previousTemp = meanTemp
      }

      bins.append(CouplerTempBin(
        id: i,
        timestamp: Date(timeIntervalSince1970: binCenter),
        temp_C: meanTemp
      ))
    }

    return bins
  }

  func displayTemp(_ celsius: Double) -> Double {
    metric
      ? celsius
      : Measurement(value: celsius, unit: UnitTemperature.celsius).converted(to: .fahrenheit).value
  }

  var tempUnit: String {
    metric ? UnitTemperature.celsius.symbol : UnitTemperature.fahrenheit.symbol
  }
}

struct ChargeDetailCouplerTempChartView: View {
  @Bindable var model: ChargeDetailCouplerTempChartModel

  @Environment(\.dismiss) var dismiss

  var body: some View {
    VStack {
      Chart {
        ForEach(model.tempBins) { bin in
          LineMark(
            x: .value("Time", bin.timestamp),
            y: .value("Temp", model.displayTemp(bin.temp_C))
          )
          .foregroundStyle(.orange)
          .interpolationMethod(.catmullRom)
        }

        if let selected = model.selectedBin {
          RuleMark(x: .value("time", selected.timestamp))
            .foregroundStyle(.gray.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

          PointMark(
            x: .value("time", selected.timestamp),
            y: .value("temp", model.displayTemp(selected.temp_C))
          )
          .foregroundStyle(.orange)
          .symbolSize(100)
          .annotation(position: .top) {
            VStack(spacing: 2) {
              Text(selected.timestamp, style: .time)
                .font(.caption2)
              Text(String(format: "%.1f %@", model.displayTemp(selected.temp_C), model.tempUnit))
                .font(.caption)
                .fontWeight(.semibold)
            }
            .padding(6)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(6)
          }
        }
      }
      .chartXAxis(.automatic)
      .chartYAxis {
        AxisMarks(position: .trailing) { value in
          if let temp = value.as(Double.self) {
            AxisGridLine()
            AxisTick()
            AxisValueLabel(String(format: "%.0f %@", temp, model.tempUnit))
          }
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
                  model.selectedBin = model.tempBins.min {
                    abs($0.timestamp.timeIntervalSince(timestamp)) < abs($1.timestamp.timeIntervalSince(timestamp))
                  }
                }
                .onEnded { _ in
                  model.selectedBin = nil
                }
            )
        }
      }
      .padding()
    }
    .navigationTitle(Text("Coupler Temperature"))
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
    ChargeDetailCouplerTempChartView(
      model: ChargeDetailCouplerTempChartModel(
        charge: charges.first!
      )
    )
    .preferredColorScheme(.dark)
  }
}
