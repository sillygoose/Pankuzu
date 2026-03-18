import SwiftUI
import Charts

import DokoSchema

struct SoHPoint: Identifiable {
  enum Source { case charge, trip }
  let id: UUID
  let date: Date
  let soh: Double
  let source: Source
  let isCurrent: Bool
}

@MainActor
@Observable
public final class SoHHistoryModel {
  var vehicleID: Vehicle.ID
  var currentID: UUID
  var points: [SoHPoint] = []

  @ObservationIgnored @FetchAll(Charge.none) var charges: [Charge]
  @ObservationIgnored @FetchAll(Trip.none) var trips: [Trip]

  public init(vehicleID: Vehicle.ID, currentID: UUID) {
    self.vehicleID = vehicleID
    self.currentID = currentID
    _charges = FetchAll(
      Charge
        .where { !$0.isDeleted }
        .where { $0.vehicleID.eq(vehicleID) }
        .where { $0.batteryStateOfHealth.isNot(nil) }
        .order { $0.timeStart.asc() }
    )
    _trips = FetchAll(
      Trip
        .where { !$0.isDeleted }
        .where { $0.vehicleID.eq(vehicleID) }
        .where { $0.batteryStateOfHealth.isNot(nil) }
        .order { $0.timeStart.asc() }
    )
    buildPoints()
  }

  func buildPoints() {
    let chargePoints = charges.compactMap { c -> SoHPoint? in
      guard let soh = c.batteryStateOfHealth else { return nil }
      return SoHPoint(id: c.id, date: c.timeStart, soh: soh, source: .charge, isCurrent: c.id == currentID)
    }
    let tripPoints = trips.compactMap { t -> SoHPoint? in
      guard let soh = t.batteryStateOfHealth else { return nil }
      return SoHPoint(id: t.id, date: t.timeStart, soh: soh, source: .trip, isCurrent: t.id == currentID)
    }
    points = (chargePoints + tripPoints).sorted { $0.date < $1.date }
  }
}

public struct SoHHistoryView: View {
  @Bindable var model: SoHHistoryModel

  @Environment(\.dismiss) var dismiss

  public init(model: SoHHistoryModel) {
    self.model = model
  }

  var yMin: Double {
    guard let min = model.points.map(\.soh).min() else { return 0 }
    return floor((min - 10) / 10) * 10
  }

  public var body: some View {
    VStack {
      Chart {
        ForEach(model.points) { point in
          LineMark(
            x: .value("Date", point.date),
            y: .value("SoH", point.soh),
            series: .value("Source", point.source == .charge ? "Charge" : "Trip")
          )
          .foregroundStyle(point.source == .charge ? Color.green : Color.blue)
          .interpolationMethod(.monotone)

          PointMark(
            x: .value("Date", point.date),
            y: .value("SoH", point.soh)
          )
          .foregroundStyle(point.isCurrent ? Color.orange : point.source == .charge ? Color.green : Color.blue)
          .symbolSize(point.isCurrent ? 120 : 40)
          .annotation(position: .top) {
            if point.isCurrent {
              Text(String(format: "%.1f%%", point.soh))
                .font(.caption2)
                .padding(4)
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(4)
            }
          }
        }
      }
      .chartYScale(domain: yMin...100)
      .chartYAxis {
        AxisMarks(position: .trailing) { value in
          if let pct = value.as(Double.self) {
            AxisGridLine()
            AxisTick()
            AxisValueLabel(String(format: "%.0f%%", pct))
          }
        }
      }
      .chartXAxis(.automatic)
      .chartLegend(position: .bottom)
      .frame(maxHeight: .infinity)
      .padding()
    }
    .navigationTitle(Text("State of Health History"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button("Done") { dismiss() }
      }
    }
  }
}
