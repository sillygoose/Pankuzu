import SwiftUI
import Charts

import DokoVehicleManager
import DokoSchema
import DokoSharing
import CommonUI

extension SharedKey where Self == AppStorageKey<Vehicle.ID?>.Default {
  static var chargeHistoryDisplayVehicleID: Self {
    Self[.appStorage("ChargeHistoryChartDisplayVehicleID"), default: nil]
  }
}

struct ChargeBarEntry: Identifiable {
  var id: String { "\(monthDate.timeIntervalSince1970)-\(type)" }
  let monthDate: Date
  let type: String
  let kWh: Double
}

@MainActor
@Observable
final class ChargeHistoryChartModel {
  @ObservationIgnored @FetchAll var vehicles: [Vehicle]
  @ObservationIgnored @FetchAll var charges: [Charge]
  @ObservationIgnored @Shared(.chargeHistoryDisplayVehicleID) var displayVehicleID

  var chartEntries: [ChargeBarEntry] = []
  var vehicleButtonTitle: String = "All Vehicles"
  var vehicleButtonImage: String = "car.2"

  let allVehiclesTitle = "All Vehicles"

  init() {
    _vehicles = FetchAll()

    let calendar = Calendar.current
    let monthStart = calendar.dateComponents([.year, .month], from: Date())
    let currentMonthStart = calendar.date(from: monthStart)!
    let windowStart = calendar.date(byAdding: .month, value: -12, to: currentMonthStart)!

    _charges = FetchAll(
      Charge
        .where { $0.isDeleted.eq(false) }
        .where { $0.timeStart.gte(windowStart) }
        .where { !$0.isNoCharge }
        .order { $0.timeStart.asc() },
      animation: .default
    )

    updateVehicleMenuLabels(vehicleID: displayVehicleID)
    computeEntries()
  }

  func computeEntries() {
    let calendar = Calendar.current
    let monthStart = calendar.dateComponents([.year, .month], from: Date())
    let currentMonthStart = calendar.date(from: monthStart)!

    let filtered = displayVehicleID.map { id in charges.filter { $0.vehicleID == id } } ?? charges

    chartEntries = (0..<13).flatMap { offset -> [ChargeBarEntry] in
      let start = calendar.date(byAdding: .month, value: -(12 - offset), to: currentMonthStart)!
      let end = calendar.date(byAdding: .month, value: 1, to: start)!
      let month = filtered.filter { $0.timeStart >= start && $0.timeStart < end }
      let acKWh = month.filter { $0.chargerType == .ac }.compactMap(\.energy).reduce(0, +)
      let dcKWh = month.filter { $0.chargerType == .dc }.compactMap(\.energy).reduce(0, +)
      return [
        ChargeBarEntry(monthDate: start, type: "AC", kWh: acKWh),
        ChargeBarEntry(monthDate: start, type: "DCFC", kWh: dcKWh),
        ChargeBarEntry(monthDate: start, type: "Total", kWh: acKWh + dcKWh),
      ]
    }
  }

  func setVehicleMenu(vehicleID: Vehicle.ID?) {
    $displayVehicleID.withLock { $0 = vehicleID }
    updateVehicleMenuLabels(vehicleID: vehicleID)
  }

  private func updateVehicleMenuLabels(vehicleID: Vehicle.ID?) {
    guard let vehicleID else {
      vehicleButtonTitle = allVehiclesTitle
      vehicleButtonImage = "car.2"
      return
    }
    if let vehicle = DokoVehicleManager.shared.lookup(id: vehicleID) {
      vehicleButtonTitle = vehicle.yearMakeModel
      vehicleButtonImage = vehicle.truck ? "truck.pickup.side" : "car.side"
    } else {
      vehicleButtonTitle = allVehiclesTitle
      vehicleButtonImage = "car.2"
    }
  }
}

struct ChargeHistoryChartView: View {
  @State var model = ChargeHistoryChartModel()
  @State private var selectedMonth: Date?

  @ChartContentBuilder
  private var barSeries: some ChartContent {
    ForEach(model.chartEntries.filter { $0.type != "Total" }) { entry in
      BarMark(
        x: .value("Month", entry.monthDate, unit: .month),
        y: .value("kWh", entry.kWh)
      )
      .foregroundStyle(by: .value("Type", entry.type))
    }
  }

  @ChartContentBuilder
  private var selectionMark: some ChartContent {
    if let month = selectedMonth,
       let ac = model.chartEntries.first(where: { $0.monthDate == month && $0.type == "AC" }),
       let dc = model.chartEntries.first(where: { $0.monthDate == month && $0.type == "DCFC" }),
       let total = model.chartEntries.first(where: { $0.monthDate == month && $0.type == "Total" }) {
      RuleMark(x: .value("Month", month, unit: .month))
        .foregroundStyle(.gray.opacity(0.5))
        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
      PointMark(
        x: .value("Month", month, unit: .month),
        y: .value("kWh", total.kWh)
      )
      .foregroundStyle(.clear)
      .annotation(position: .top) {
        VStack(spacing: 2) {
          Text(month, format: .dateTime.month(.wide).year())
            .font(.caption2)
          Text(String(format: "%.1f kWh Total", total.kWh))
            .font(.caption).fontWeight(.semibold).foregroundStyle(Color.blue)
          Text(String(format: "%.1f kWh AC", ac.kWh))
            .font(.caption).fontWeight(.semibold).foregroundStyle(Color.orange)
          Text(String(format: "%.1f kWh DCFC", dc.kWh))
            .font(.caption).fontWeight(.semibold).foregroundStyle(Color.green)
        }
        .padding(6)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(6)
      }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      Menu {
        Button {
          model.setVehicleMenu(vehicleID: nil)
          model.computeEntries()
        } label: {
          Text(model.allVehiclesTitle)
          Image(systemName: model.displayVehicleID == nil ? "checkmark" : "car.2")
        }
        ForEach(model.vehicles) { vehicle in
          Button {
            model.setVehicleMenu(vehicleID: vehicle.id)
            model.computeEntries()
          } label: {
            Text(vehicle.yearMakeModel)
            Image(systemName: model.displayVehicleID == vehicle.id ? "checkmark" : (vehicle.truck ? "truck.pickup.side" : "car.side"))
          }
        }
      } label: {
        GridButton(color: .mint, symbolName: model.vehicleButtonImage, title: model.vehicleButtonTitle) {}
      }
      .padding(.horizontal)
      .padding(.vertical, 8)

      if model.chartEntries.allSatisfy({ $0.kWh == 0 }) {
        ContentUnavailableView(
          "No Data",
          systemImage: "bolt.slash",
          description: Text("No charging sessions were logged in the past year.")
        )
      } else {
        Chart {
          barSeries
          selectionMark
        }
        .chartForegroundStyleScale([
          "AC": Color.orange,
          "DCFC": Color.green
        ])
        .chartXAxis {
          AxisMarks(values: .stride(by: .month)) { _ in
            AxisValueLabel(format: .dateTime.month(.abbreviated))
            AxisGridLine()
          }
        }
        .chartYAxis {
          AxisMarks { value in
            AxisValueLabel(String(format: "%.0f kWh", value.as(Double.self) ?? 0))
            AxisGridLine()
          }
        }
        .chartLegend(position: .bottom, alignment: .center, spacing: 16)
        .chartOverlay { proxy in
          GeometryReader { geometry in
            Rectangle()
              .fill(.clear)
              .contentShape(Rectangle())
              .gesture(
                DragGesture(minimumDistance: 0)
                  .onChanged { value in
                    let x = value.location.x - geometry[proxy.plotFrame!].origin.x
                    guard let date: Date = proxy.value(atX: x) else { return }
                    let months = model.chartEntries.map(\.monthDate)
                    selectedMonth = months.min {
                      abs($0.timeIntervalSince(date)) < abs($1.timeIntervalSince(date))
                    }
                  }
                  .onEnded { _ in selectedMonth = nil }
              )
          }
        }
        .frame(height: 280)
        .padding(.horizontal)
      }
      Spacer()
    }
    .navigationTitle("Charge History")
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: model.charges.count) { _, _ in model.computeEntries() }
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    ChargeHistoryChartView()
      .preferredColorScheme(.dark)
  }
}
