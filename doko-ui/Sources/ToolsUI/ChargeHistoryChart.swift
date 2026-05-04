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

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
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
          GridButton(
            color: .mint,
            symbolName: model.vehicleButtonImage,
            title: model.vehicleButtonTitle
          ) {}
        }
        .padding(.horizontal)

        Chart {
          ForEach(model.chartEntries) { entry in
            BarMark(
              x: .value("Month", entry.monthDate, unit: .month),
              y: .value("kWh", entry.kWh)
            )
            .foregroundStyle(by: .value("Type", entry.type))
            .position(by: .value("Type", entry.type))
          }
        }
        .chartForegroundStyleScale([
          "AC": Color.orange,
          "DCFC": Color.green,
          "Total": Color.blue
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
        .frame(height: 280)
        .padding(.horizontal)

      }
      .padding(.vertical)
    }
    .navigationTitle("Charge History")
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: model.charges.count) { _, _ in
      model.computeEntries()
    }
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
