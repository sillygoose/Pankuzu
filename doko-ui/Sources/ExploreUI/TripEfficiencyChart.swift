import SwiftUI
import Charts

import DokoVehicleManager
import DokoSchema
import DokoSharing
import CommonUI

extension SharedKey where Self == AppStorageKey<Vehicle.ID?>.Default {
  static var tripEfficiencyDisplayVehicleID: Self {
    Self[.appStorage("TripEfficiencyDisplayVehicleID"), default: nil]
  }
}

extension SharedKey where Self == AppStorageKey<TripEfficiencyUnit>.Default {
  static var tripEfficiencyUnit: Self {
    Self[.appStorage("TripEfficiencyUnit"), default: .kmPerKWh]
  }
}

enum TripEfficiencyUnit: String, CaseIterable, Codable, Hashable, Sendable {
  case milesPerKWh = "mi/kWh"
  case kmPerKWh = "km/kWh"
  case kWhPer100km = "kWh/100km"
}

fileprivate struct TripTemperature: Identifiable {
  var id: TimeInterval { monthDate.timeIntervalSince1970 }
  let monthDate: Date
  var temperature: Measurement<UnitTemperature>
}

fileprivate struct TripEfficiency: Identifiable {
  var id: TimeInterval { monthDate.timeIntervalSince1970 }
  let monthDate: Date
  var efficiency: Measurement<UnitEnergyEfficiency>
}

fileprivate struct MonthlyMileage: Identifiable {
  var id: TimeInterval { monthDate.timeIntervalSince1970 }
  let monthDate: Date
  var distanceKm: Double
}

@MainActor
@Observable
final class TripEfficiencyChartModel {
  @ObservationIgnored @FetchAll var vehicles: [Vehicle]
  @ObservationIgnored @FetchAll var trips: [Trip]
  
  @ObservationIgnored @Shared(.tripEfficiencyDisplayVehicleID) var displayVehicleID
  @ObservationIgnored @Shared(.tripEfficiencyUnit) var efficiencyUnit

  fileprivate var temperatureEntries: [TripTemperature] = []
  fileprivate var selectedTemperatureEntry: TripTemperature?
  var temperatureMin: Measurement<UnitTemperature> = Measurement(value: 0, unit: UnitTemperature.celsius)
  var temperatureMax: Measurement<UnitTemperature> = Measurement(value: 45, unit: UnitTemperature.celsius)

  fileprivate var monthlyMileageEntries: [MonthlyMileage] = []
  fileprivate var efficiencyEntries: [TripEfficiency] = []
  fileprivate var selectedEfficiencyEntry: TripEfficiency?
  var efficiencyMin: Measurement<UnitEnergyEfficiency> = Measurement(value: 0, unit: UnitEnergyEfficiency.kilometersPerKilowattHour)
  var efficiencyMax: Measurement<UnitEnergyEfficiency> = Measurement(value: 10, unit: UnitEnergyEfficiency.kilometersPerKilowattHour)

  var vehicleButtonTitle: String = "All Vehicles"
  var vehicleButtonImage: String = "car.2"

  let allVehiclesTitle = "All Vehicles"

  var temperatureUnit: String {
    switch efficiencyUnit {
    case .kmPerKWh, .kWhPer100km:
      return UnitTemperature.celsius.symbol
    case .milesPerKWh:
      return UnitTemperature.fahrenheit.symbol
    }
  }

  var temperatureConversionUnit: UnitTemperature {
    switch efficiencyUnit {
    case .kmPerKWh, .kWhPer100km:
      return UnitTemperature.celsius
    case .milesPerKWh:
      return UnitTemperature.fahrenheit
    }
  }

  var efficiencyConversionUnit: UnitEnergyEfficiency {
    switch efficiencyUnit {
    case .kmPerKWh:
      return UnitEnergyEfficiency.kilometersPerKilowattHour
    case .kWhPer100km:
      return UnitEnergyEfficiency.kilowattHoursPer100Kilometers
    case .milesPerKWh:
      return UnitEnergyEfficiency.milesPerKilowattHour
    }
  }

  var temperatureAxisMin: Double {
    temperatureMin.converted(to: temperatureConversionUnit).value
  }

  var temperatureAxisMax: Double {
    temperatureMax.converted(to: temperatureConversionUnit).value
  }

  var efficiencyAxisMin: Double {
    let a = efficiencyMin.converted(to: efficiencyConversionUnit).value
    let b = efficiencyMax.converted(to: efficiencyConversionUnit).value
    return min(a, b)
  }

  var efficiencyAxisMax: Double {
    let a = efficiencyMin.converted(to: efficiencyConversionUnit).value
    let b = efficiencyMax.converted(to: efficiencyConversionUnit).value
    return max(a, b)
  }

  var efficiencyAnnotationFormat: String {
    switch efficiencyUnit {
    case .kmPerKWh, .milesPerKWh: return "%.2f"
    case .kWhPer100km: return "%.1f"
    }
  }
  
  var efficiencyAxisFormat: String {
    switch efficiencyUnit {
    case .kmPerKWh, .milesPerKWh: return "%.1f"
    case .kWhPer100km: return "%.0f"
    }
  }

  var distanceUnit: String {
    switch efficiencyUnit {
    case .milesPerKWh: return "mi"
    case .kmPerKWh, .kWhPer100km: return "km"
    }
  }

  var distanceConversionFactor: Double {
    switch efficiencyUnit {
    case .milesPerKWh: return 0.621371
    case .kmPerKWh, .kWhPer100km: return 1.0
    }
  }

  // Maps a temperature display value onto the efficiency y-axis scale (0...efficiencyAxisMax)
  func normalizeTemperature(_ temp: Double) -> Double {
    let tempRange = temperatureAxisMax - temperatureAxisMin
    guard tempRange > 0, efficiencyAxisMax > 0 else { return 0 }
    return max(0, (temp - temperatureAxisMin) / tempRange * efficiencyAxisMax)
  }

  // Inverse — used to label right-axis ticks with actual temperature
  func temperatureFromNormalized(_ normalized: Double) -> Double {
    guard efficiencyAxisMax > 0 else { return temperatureAxisMin }
    return temperatureAxisMin + (normalized / efficiencyAxisMax) * (temperatureAxisMax - temperatureAxisMin)
  }

  // Normalized y-positions (on efficiency scale) for 5 right-axis temperature ticks
  var temperatureAxisTicks: [Double] {
    guard temperatureAxisMax > temperatureAxisMin else { return [] }
    return (0..<5).map { i in
      let temp = temperatureAxisMin + Double(i) / 4.0 * (temperatureAxisMax - temperatureAxisMin)
      return normalizeTemperature(temp)
    }
  }

  init() {
    _vehicles = FetchAll()

    let calendar = Calendar.current
    let monthStart = calendar.dateComponents([.year, .month], from: Date())
    let currentMonthStart = calendar.date(from: monthStart)!
    let windowStart = calendar.date(byAdding: .month, value: -12, to: currentMonthStart)!

    _trips = FetchAll(
      Trip
        .where { $0.isDeleted.eq(false) }
        .where { $0.timeStart.gte(windowStart) }
        .order { $0.timeStart.asc() },
      animation: .default
    )

    updateVehicleMenuLabels(vehicleID: displayVehicleID)
    computeEntries()
  }

  var windowStart: Date = Date()
  var windowEnd: Date = Date()

  func computeEntries() {
    let calendar = Calendar.current
    let monthStart = calendar.dateComponents([.year, .month], from: Date())
    let currentMonthStart = calendar.date(from: monthStart)!

    windowStart = calendar.date(byAdding: .month, value: -12, to: currentMonthStart)!
    windowEnd = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)!

    let filtered = displayVehicleID.map { id in trips.filter { $0.vehicleID == id } } ?? trips

    temperatureEntries = (0..<13).compactMap { offset in
      let start = calendar.date(byAdding: .month, value: -(12 - offset), to: currentMonthStart)!
      let end = calendar.date(byAdding: .month, value: 1, to: start)!
      let month = filtered.filter { $0.timeStart >= start && $0.timeStart < end }

      let tempTrips = month.compactMap { trip -> (weighted: Double, duration: Double)? in
        guard let weighted = trip.weatherTempMeanWeighted else { return nil }
        return (weighted, trip.duration)
      }
      guard !tempTrips.isEmpty else { return nil }
      let totalDuration = tempTrips.map(\.duration).reduce(0, +)
      guard totalDuration > 0 else { return nil }
      let rawMeanTemperature = tempTrips.map(\.weighted).reduce(0, +) / totalDuration
      return TripTemperature(monthDate: start, temperature: Measurement(value: rawMeanTemperature, unit: .celsius))
    }
    temperatureMin.value = floor((temperatureEntries.map(\.temperature.value).min() ?? 0) - 3)
    temperatureMax.value = ceil((temperatureEntries.map(\.temperature.value).max() ?? 1) + 3)

    efficiencyEntries = (0..<13).compactMap { offset in
      let start = calendar.date(byAdding: .month, value: -(12 - offset), to: currentMonthStart)!
      let end = calendar.date(byAdding: .month, value: 1, to: start)!
      let month = filtered.filter { $0.timeStart >= start && $0.timeStart < end }

      let efficiencyTrips = month.compactMap { trip -> (energy: Double, distance: Double)? in
        guard let energy = trip.energy else { return nil }
        return (energy, trip.distance)
      }
      guard !efficiencyTrips.isEmpty else { return nil }
      let totalEnergy = efficiencyTrips.map(\.energy).reduce(0, +)
      guard totalEnergy > 0 else { return nil }
      let rawEfficiency = efficiencyTrips.map(\.distance).reduce(0, +) / totalEnergy
      return TripEfficiency(monthDate: start, efficiency: Measurement(value: rawEfficiency, unit: .kilometersPerKilowattHour))
    }

    monthlyMileageEntries = (0..<13).compactMap { offset in
      let start = calendar.date(byAdding: .month, value: -(12 - offset), to: currentMonthStart)!
      let end = calendar.date(byAdding: .month, value: 1, to: start)!
      let month = filtered.filter { $0.timeStart >= start && $0.timeStart < end }
      let total = month.map(\.distance).reduce(0, +)
      guard total > 0 else { return nil }
      return MonthlyMileage(monthDate: start, distanceKm: total)
    }

    // Set efficiency axis bounds in km/kWh with a 15% buffer
    let effValues = efficiencyEntries.map(\.efficiency.value)
    if let lo = effValues.min(), let hi = effValues.max() {
      let buffer = max(0.5, (hi - lo) * 0.15)
      efficiencyMin = Measurement(value: max(0, lo - buffer), unit: .kilometersPerKilowattHour)
      efficiencyMax = Measurement(value: hi + buffer, unit: .kilometersPerKilowattHour)
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

struct TripEfficiencyChartView: View {
  @State var model = TripEfficiencyChartModel()

  @ChartContentBuilder
  private var efficiencySeries: some ChartContent {
    ForEach(model.efficiencyEntries) { entry in
      let eff = entry.efficiency.converted(to: model.efficiencyConversionUnit).value
      LineMark(
        x: .value("Month", entry.monthDate, unit: .month),
        y: .value(model.efficiencyUnit.rawValue, eff)
      )
      .foregroundStyle(by: .value("Series", "Efficiency (\(model.efficiencyUnit.rawValue))"))
      .symbol(by: .value("Series", "Efficiency (\(model.efficiencyUnit.rawValue))"))
    }
  }

  @ChartContentBuilder
  private var temperatureSeries: some ChartContent {
    ForEach(model.temperatureEntries) { entry in
      let temp = entry.temperature.converted(to: model.temperatureConversionUnit).value
      LineMark(
        x: .value("Month", entry.monthDate, unit: .month),
        y: .value(model.temperatureUnit, model.normalizeTemperature(temp))
      )
      .foregroundStyle(by: .value("Series", "Temperature (\(model.temperatureUnit))"))
      .symbol(by: .value("Series", "Temperature (\(model.temperatureUnit))"))
    }
  }

  @ChartContentBuilder
  private var selectionMark: some ChartContent {
    if let selected = model.selectedTemperatureEntry {
      let eff = model.efficiencyEntries.first(where: { $0.monthDate == selected.monthDate })
        .map { $0.efficiency.converted(to: model.efficiencyConversionUnit).value }
      RuleMark(x: .value("Month", selected.monthDate, unit: .month))
        .foregroundStyle(.gray.opacity(0.5))
        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
      PointMark(
        x: .value("Month", selected.monthDate, unit: .month),
        y: .value(model.efficiencyUnit.rawValue, eff ?? model.efficiencyAxisMax)
      )
      .foregroundStyle(.clear)
      .annotation(position: .top) {
        VStack(spacing: 2) {
          Text(selected.monthDate, format: .dateTime.month(.wide).year())
            .font(.caption2)
          if let eff {
            Text(String(format: "\(model.efficiencyAnnotationFormat) \(model.efficiencyUnit.rawValue)", eff))
              .font(.caption).fontWeight(.semibold).foregroundStyle(Color.green)
          }
          let temp = selected.temperature.converted(to: model.temperatureConversionUnit).value
          Text(String(format: "%.1f%@", temp, model.temperatureUnit))
            .font(.caption).fontWeight(.semibold).foregroundStyle(Color.orange)
        }
        .padding(6)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(6)
      }
    }
  }

  var body: some View {
    ScrollView {
    VStack(spacing: 0) {
      Picker("Efficiency Unit", selection: Binding(
        get: { model.efficiencyUnit },
        set: { newValue in model.$efficiencyUnit.withLock { $0 = newValue } }
      )) {
        ForEach(TripEfficiencyUnit.allCases, id: \.self) { unit in
          Text(unit.rawValue).tag(unit)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal)
      .padding(.vertical, 20)

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
      .padding(.bottom, 20)

      if model.efficiencyEntries.isEmpty && model.temperatureEntries.isEmpty {
        ContentUnavailableView(
          "No Data",
          systemImage: "chart.bar.xaxis",
          description: Text("No trips with energy and weather data logged in the past year.")
        )
      } else {
        Chart {
          efficiencySeries
          temperatureSeries
          selectionMark
        }
        .chartForegroundStyleScale([
          "Efficiency (\(model.efficiencyUnit.rawValue))": Color.green,
          "Temperature (\(model.temperatureUnit))": Color.orange
        ])
        .chartXScale(domain: model.windowStart...model.windowEnd)
        .chartYScale(domain: 0...model.efficiencyAxisMax)
        .chartXAxis {
          AxisMarks(values: .stride(by: .month)) { _ in
            AxisValueLabel(format: .dateTime.month(.abbreviated))
            AxisGridLine()
          }
        }
        .chartYAxis {
          AxisMarks(position: .leading) { value in
            AxisValueLabel(String(format: "\(model.efficiencyAxisFormat)", value.as(Double.self) ?? 0))
            AxisGridLine()
          }
          AxisMarks(position: .trailing, values: model.temperatureAxisTicks) { value in
            if let normalized = value.as(Double.self) {
              let temp = model.temperatureFromNormalized(normalized)
              AxisValueLabel(String(format: "%.0f\(model.temperatureUnit)", temp))
            }
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
                    model.selectedTemperatureEntry = model.temperatureEntries.min {
                      abs($0.monthDate.timeIntervalSince(date)) < abs($1.monthDate.timeIntervalSince(date))
                    }
                  }
                  .onEnded { _ in model.selectedTemperatureEntry = nil }
              )
          }
        }
        .frame(height: 300)
        .padding(.horizontal)
        .padding(.bottom, 30)

        if !model.monthlyMileageEntries.isEmpty {
          HStack {
            Text("Monthly Totals")
              .font(.headline)
          }
          .padding(.horizontal)
          VStack(spacing: 0) {
            ForEach(model.monthlyMileageEntries.reversed()) { entry in
              HStack {
                Text(entry.monthDate, format: .dateTime.month(.wide).year())
                  .foregroundStyle(.primary)
                Spacer()
                Text(String(format: "%.0f %@", entry.distanceKm * model.distanceConversionFactor, model.distanceUnit))
                  .foregroundStyle(.secondary)
              }
              .padding(.horizontal)
              .padding(.vertical, 10)
              Divider()
                .padding(.leading)
            }
          }
          .padding(.top, 16)
        }
      }
    }
    } // ScrollView
    .navigationTitle("Trip Efficiency")
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: model.trips.count) { _, _ in model.computeEntries() }
    .onChange(of: model.efficiencyUnit) { _, _ in model.computeEntries() }
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    TripEfficiencyChartView()
      .preferredColorScheme(.dark)
  }
}
