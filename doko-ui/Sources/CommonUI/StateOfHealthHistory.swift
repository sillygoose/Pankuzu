import SwiftUI
import Charts

import DokoSchema
import DokoSharing

extension SharedKey where Self == AppStorageKey<StateOfHealthPeriod>.Default {
  static var stateOfHealthDisplayPeriod: Self {
    Self[.appStorage("StateOfHealtHistoryDisplayhPeriod"), default: .week]
  }
}

struct StateOfHealthPoint: Identifiable {
  enum Source { case charge, trip }
  let id: UUID
  let date: Date
  let soh: Double
  let source: Source
  let isCurrent: Bool
}

enum StateOfHealthPeriod: String, CaseIterable {
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
public final class StateOfHealthHistoryModel {
  var vehicleID: Vehicle.ID
  var currentID: UUID
  var points: [StateOfHealthPoint] = []

  @ObservationIgnored @FetchAll(Charge.none) var charges: [Charge]
  @ObservationIgnored @FetchAll(Trip.none) var trips: [Trip]
  @ObservationIgnored @Shared(.stateOfHealthDisplayPeriod) var displayPeriod
  var scrollPosition: Date = Date()

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
//    scrollPosition = Date()
    buildPoints()
    anchorToNow()
  }

  func buildPoints() {
    let chargePoints = charges.compactMap { c -> StateOfHealthPoint? in
      guard let soh = c.batteryStateOfHealth else { return nil }
      return StateOfHealthPoint(id: c.id, date: c.timeStart, soh: soh, source: .charge, isCurrent: c.id == currentID)
    }
    let tripPoints = trips.compactMap { t -> StateOfHealthPoint? in
      guard let soh = t.batteryStateOfHealth else { return nil }
      return StateOfHealthPoint(id: t.id, date: t.timeStart, soh: soh, source: .trip, isCurrent: t.id == currentID)
    }
    points = (chargePoints + tripPoints).sorted { $0.date < $1.date }
  }

  @discardableResult
  func setDisplayPeriod(_ newPeriod: StateOfHealthPeriod) -> StateOfHealthPeriod {
    $displayPeriod.withLock { $0 = newPeriod }
    return newPeriod
  }

  var xDomainStart: Date {
    points.first?.date ?? Date().addingTimeInterval(-displayPeriod.visibleInterval)
  }

  func anchorToNow() {
    scrollPosition = Date().addingTimeInterval(-displayPeriod.visibleInterval)
  }
}

public struct StateOfHealthHistoryView: View {
  @Bindable var model: StateOfHealthHistoryModel
  @State private var selectedDate: Date?

  @Environment(\.dismiss) var dismiss

  public init(
    model: StateOfHealthHistoryModel
  ) {
    self.model = model
  }

  var yMin: Double {
    guard let min = model.points.map(\.soh).min() else { return 0 }
    return floor((min - 10) / 10) * 10
  }

  var selectedPoint: StateOfHealthPoint? {
    guard let date = selectedDate else { return nil }
    return model.points.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
  }

  public var body: some View {
    VStack(spacing: 0) {
      Picker("Period", selection: Binding(
        get: { model.displayPeriod },
        set: { newValue in model.$displayPeriod.withLock { $0 = newValue } }
      )) {
        ForEach(StateOfHealthPeriod.allCases, id: \.self) { period in
          Text(period.rawValue).tag(period)
        }
      }
      .pickerStyle(.segmented)
      .padding()

      Chart {
        ForEach(model.points) { point in
          LineMark(
            x: .value("Date", point.date),
            y: .value("SoH", point.soh)
          )
          .foregroundStyle(.secondary)
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

        if let point = selectedPoint {
          RuleMark(x: .value("Date", point.date))
            .foregroundStyle(Color.primary.opacity(0.3))
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
      .chartXVisibleDomain(length: model.displayPeriod.visibleInterval)
      .chartScrollPosition(x: $model.scrollPosition)
      .chartXScale(domain: model.xDomainStart...Date())
      .chartXAxis {
        AxisMarks(values: .stride(by: model.displayPeriod.axisStride)) { _ in
          AxisGridLine()
          AxisTick()
          AxisValueLabel(format: model.displayPeriod.axisFormat)
        }
      }
      .chartXSelection(value: $selectedDate)
      .chartLegend(.hidden)
      .overlay(alignment: .topLeading) {
        if let point = selectedPoint {
          VStack(alignment: .leading, spacing: 2) {
            Text(String(format: "%.1f%%", point.soh))
              .font(.caption.bold())
            Text(point.date, format: .dateTime.month(.abbreviated).day().year(.twoDigits))
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 5)
          .background(Color(.systemBackground).opacity(0.95))
          .clipShape(RoundedRectangle(cornerRadius: 6))
          .shadow(radius: 2)
          .padding(8)
        }
      }
      .frame(maxHeight: .infinity)
      .padding(.horizontal)

      HStack(spacing: 20) {
        HStack(spacing: 6) {
          Circle().fill(Color.green).frame(width: 8, height: 8)
          Text("Charge").font(.caption).foregroundStyle(.secondary)
        }
        HStack(spacing: 6) {
          Circle().fill(Color.blue).frame(width: 8, height: 8)
          Text("Trip").font(.caption).foregroundStyle(.secondary)
        }
      }
      .padding(.bottom, 8)
    }
    .navigationTitle(Text("State of Health History"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button("Done") { dismiss() }
      }
    }
    .onChange(of: model.displayPeriod) { model.anchorToNow() }
  }
}
