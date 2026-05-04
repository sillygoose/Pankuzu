import SwiftUI
import Charts

import DokoVehicleManager
import DokoSchema
import DokoSharing
import CommonUI

extension SharedKey where Self == AppStorageKey<Vehicle.ID?>.Default {
  static var tripEfficiencyDisplayVehicleID: Self {
    Self[.appStorage("TripDisplayVehicleID"), default: nil]
  }
}

extension SharedKey where Self == AppStorageKey<TripEfficiencyUnit>.Default {
  static var tripEfficiencyUnit: Self {
    Self[.appStorage("tripEfficiencyUnit"), default: .kmPerKWh]
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

  fileprivate var efficiencyEntries: [TripEfficiency] = []
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
    return temperatureMin.converted(to: temperatureConversionUnit).value
  }

  var temperatureAxisMax: Double {
    return temperatureMax.converted(to: temperatureConversionUnit).value
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
    let minYAxis = floor((temperatureEntries.map(\.temperature.value).min() ?? 0) - 10)
    let maxYAxis = ceil((temperatureEntries.map(\.temperature.value).max() ?? 1) + 10)
    temperatureMin.value = min(0.0, minYAxis)
    temperatureMax.value = max(45.0, maxYAxis)
//    for (_, temperature) in temperatureEntries.enumerated() {
//      print(temperature.temperature.converted(to: temperatureConversionUnit))
//    }

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
//    for (_, efficiency) in efficiencyEntries.enumerated() {
//      print(efficiency.efficiency.converted(to: efficiencyConversionUnit))
//    }
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

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
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

        Chart(model.temperatureEntries) { entry in
          let temperature = entry.temperature.converted(to: model.temperatureConversionUnit).value
          BarMark(
            x: .value("Month", entry.monthDate, unit: .month),
            yStart: .value("Temp Min", model.temperatureAxisMin),
            yEnd: .value(model.temperatureUnit, temperature)
          )
          if let selected = model.selectedTemperatureEntry, selected.id == entry.id {
            RuleMark(x: .value("Month", entry.monthDate, unit: .month))
              .foregroundStyle(.gray.opacity(0.5))
              .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            PointMark(
              x: .value("Month", entry.monthDate, unit: .month),
              y: .value(model.temperatureUnit, temperature)
            )
            .foregroundStyle(.clear)
            .annotation(position: temperature >= 0 ? .top : .bottom) {
              VStack(spacing: 2) {
                Text(entry.monthDate, format: .dateTime.month(.wide).year())
                  .font(.caption2)
                Text(String(format: "%.1f%@", temperature, model.temperatureUnit))
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundStyle(Color.orange)
              }
              .padding(6)
              .background(Color(.systemBackground).opacity(0.9))
              .cornerRadius(6)
            }
          }
        }
        .chartForegroundStyleScale(["Mean Temperature (\(model.temperatureUnit))": Color.orange])
        .chartXScale(domain: model.windowStart...model.windowEnd)
        .chartYScale(domain: model.temperatureAxisMin...model.temperatureAxisMax)
        .chartXAxis {
          AxisMarks(values: .stride(by: .month)) { _ in
            AxisValueLabel(format: .dateTime.month(.abbreviated))
            AxisGridLine()
          }
        }
        .chartYAxis {
          AxisMarks { value in
            AxisValueLabel(String(format: "%.0f \(model.temperatureUnit)", value.as(Double.self) ?? 0))
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
                    model.selectedTemperatureEntry = model.temperatureEntries.min {
                      abs($0.monthDate.timeIntervalSince(date)) < abs($1.monthDate.timeIntervalSince(date))
                    }
                  }
                  .onEnded { _ in model.selectedTemperatureEntry = nil }
              )
          }
        }
        .frame(height: 280)
        .padding(.horizontal)
      }
      .padding(.vertical)
    }
    .navigationTitle("Trip Efficiency")
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: model.trips.count) { _, _ in
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
    TripEfficiencyChartView()
      .preferredColorScheme(.dark)
  }
}
