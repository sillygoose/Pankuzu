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

enum SoHPeriod: String, CaseIterable {
  case week = "Week"
  case month = "Month"
  case year = "Year"

  var visibleInterval: TimeInterval {
    switch self {
    case .week:  return 7 * 24 * 3600
    case .month: return 30 * 24 * 3600
    case .year:  return 365 * 24 * 3600
    }
  }

  var axisStride: Calendar.Component {
    switch self {
    case .week:  return .day
    case .month: return .weekOfYear
    case .year:  return .month
    }
  }

  var axisFormat: Date.FormatStyle {
    switch self {
    case .week:  return .dateTime.month(.abbreviated).day()
    case .month: return .dateTime.month(.abbreviated).day()
    case .year:  return .dateTime.month(.abbreviated).year(.twoDigits)
    }
  }
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
        .where { $0.isDeleted.eq(false) }
        .where { $0.vehicleID.eq(vehicleID) }
        .where { $0.batteryStateOfHealth.isNot(nil) }
        .order { $0.timeStart.asc() }
    )
    _trips = FetchAll(
      Trip
        .where { $0.isDeleted.eq(false) }
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
  @State private var period: SoHPeriod = .month
  @State private var scrollPosition: Date = Date()

  public init(model: SoHHistoryModel) {
    self.model = model
  }

  var yMin: Double {
    guard let min = model.points.map(\.soh).min() else { return 0 }
    return floor((min - 10) / 10) * 10
  }

  var xDomainStart: Date {
    model.points.first?.date ?? Date().addingTimeInterval(-period.visibleInterval)
  }

  func anchorToNow() {
    scrollPosition = Date().addingTimeInterval(-period.visibleInterval)
  }

  public var body: some View {
    VStack(spacing: 0) {
      Picker("Period", selection: $period) {
        ForEach(SoHPeriod.allCases, id: \.self) { p in
          Text(p.rawValue).tag(p)
        }
      }
      .pickerStyle(.segmented)
      .padding()

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
      .chartYScale(domain: yMin...102)
      .chartYAxis {
        AxisMarks(position: .trailing) { value in
          if let pct = value.as(Double.self) {
            AxisGridLine()
            AxisTick()
            AxisValueLabel(String(format: "%.0f%%", pct))
          }
        }
      }
      .chartScrollableAxes(.horizontal)
      .chartXVisibleDomain(length: period.visibleInterval)
      .chartScrollPosition(x: $scrollPosition)
      .chartXScale(domain: xDomainStart...Date())
      .chartXAxis {
        AxisMarks(values: .stride(by: period.axisStride)) { _ in
          AxisGridLine()
          AxisTick()
          AxisValueLabel(format: period.axisFormat)
        }
      }
      .chartLegend(position: .bottom)
      .frame(maxHeight: .infinity)
      .padding(.horizontal)
    }
    .navigationTitle(Text("State of Health History"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button("Done") { dismiss() }
      }
    }
    .onAppear { anchorToNow() }
    .onChange(of: period) { anchorToNow() }
    .onChange(of: model.charges.count) { model.buildPoints() }
    .onChange(of: model.trips.count) { model.buildPoints() }
  }
}
