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

enum TripEfficiencyUnit: String, CaseIterable, Codable, Hashable, Sendable {
  case milesPerKWh = "mi/kWh"
  case kmPerKWh = "km/kWh"
  case kWhPer100km = "kWh/100km"
}

extension SharedKey where Self == AppStorageKey<TripEfficiencyUnit>.Default {
  static var tripEfficiencyUnit: Self {
    Self[.appStorage("tripEfficiencyUnit"), default: .kmPerKWh]
  }
}

struct TripTemperatureEntry: Identifiable {
  var id: TimeInterval { monthDate.timeIntervalSince1970 }
  let monthDate: Date
  var temperature: Double
}

@MainActor
@Observable
final class TripEfficiencyChartModel {
  @ObservationIgnored @FetchAll var vehicles: [Vehicle]
  @ObservationIgnored @FetchAll var trips: [Trip]
  @ObservationIgnored @Shared(.tripEfficiencyDisplayVehicleID) var displayVehicleID
  @ObservationIgnored @Shared(.appSettings) var appSettings
  @ObservationIgnored @Shared(.tripEfficiencyUnit) var efficiencyUnit

  var temperatureEntries: [TripTemperatureEntry] = []
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

  var yAxisMin: Double {
    switch efficiencyUnit {
    case .kmPerKWh, .kWhPer100km:
      return 0
    case .milesPerKWh:
      return 30
    }
//    let minThreshold = 0.0 //appSettings.metric ? 0.0 : 32.0
//    return minThreshold
//    let buffer = appSettings.metric ? 5.0 : 10.0
//    let actualMin = temperatureEntries.map(\.temperature).min() ?? minThreshold
//    return actualMin < minThreshold ? actualMin - buffer : minThreshold
  }

  var yAxisMax: Double {
    switch efficiencyUnit {
    case .kmPerKWh, .kWhPer100km:
      return 45
    case .milesPerKWh:
      return 100
    }
//    let maxThreshold = 45.0 //appSettings.metric ? 40.0 : 104.0
//    return maxThreshold
//    let buffer = appSettings.metric ? 5.0 : 9.0
//    let actualMax = temperatureEntries.map(\.temperature).max() ?? maxThreshold
//    return actualMax > maxThreshold ? actualMax + buffer : maxThreshold
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
//    let isMetric = appSettings.metric

    windowStart = calendar.date(byAdding: .month, value: -12, to: currentMonthStart)!
    windowEnd = calendar.date(byAdding: .month, value: 1, to: currentMonthStart)!

    let filtered = displayVehicleID.map { id in trips.filter { $0.vehicleID == id } } ?? trips

    temperatureEntries = (0..<13).compactMap { offset in
      let start = calendar.date(byAdding: .month, value: -(12 - offset), to: currentMonthStart)!
      let end = calendar.date(byAdding: .month, value: 1, to: start)!
      let month = filtered.filter { $0.timeStart >= start && $0.timeStart < end }

      // weatherTempMeanWeighted is Σ(temp × dt) per trip; monthly mean = Σ(weighted) / Σ(duration)
      let tempTrips = month.compactMap { trip -> (weighted: Double, duration: Double)? in
        guard let weighted = trip.weatherTempMeanWeighted else { return nil }
        return (weighted, trip.duration)
      }
      guard !tempTrips.isEmpty else { return nil }
      let totalDuration = tempTrips.map(\.duration).reduce(0, +)
      guard totalDuration > 0 else { return nil }
      let rawMeanTemperature = tempTrips.map(\.weighted).reduce(0, +) / totalDuration
//      let displayTemp = isMetric ? meanC : meanC * 9 / 5 + 32
      let temperatureUnit: UnitTemperature = {
        switch efficiencyUnit {
        case .kmPerKWh, .kWhPer100km:
          return UnitTemperature.celsius
        case .milesPerKWh:
          return UnitTemperature.fahrenheit
        }
      }()
      let temperature = Measurement(value: rawMeanTemperature, unit: .celsius)
        .converted(to: temperatureUnit)
      print(temperature)
      return TripTemperatureEntry(monthDate: start, temperature: temperature.value)
    }
  }
  
//  @discardableResult
  func setDisplayPeriod(_ newUnit: TripEfficiencyUnit) {
    let oldTemperatureUnit: UnitTemperature = {
      switch efficiencyUnit {
      case .kmPerKWh, .kWhPer100km:
        return UnitTemperature.celsius
      case .milesPerKWh:
        return UnitTemperature.fahrenheit
      }
    }()
    let newTemperatureUnit: UnitTemperature = {
      switch newUnit {
      case .kmPerKWh, .kWhPer100km:
        return UnitTemperature.celsius
      case .milesPerKWh:
        return UnitTemperature.fahrenheit
      }
    }()
    $efficiencyUnit.withLock { $0 = newUnit }
   
    for i in temperatureEntries.indices {
      let measurement = Measurement(value: temperatureEntries[i].temperature, unit: oldTemperatureUnit)
        .converted(to: newTemperatureUnit)
      temperatureEntries[i].temperature = measurement.value
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

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Picker("Efficiency Unit", selection: Binding(
          get: { model.efficiencyUnit },
          set: { model.setDisplayPeriod($0) }
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
          BarMark(
            x: .value("Month", entry.monthDate, unit: .month),
            yStart: .value("Temp Min", model.yAxisMin),
            yEnd: .value(model.temperatureUnit, entry.temperature)
//            y: .value(model.temperatureUnit, entry.temperature)
          )
//          .foregroundStyle(by: .value("Series", "Mean Temp (\(model.temperatureUnit))"))
        }
//        .chartForegroundStyleScale(["Mean Temperature (\(model.temperatureUnit))": Color.orange])
        .chartXScale(domain: model.windowStart...model.windowEnd)
        .chartYScale(domain: model.yAxisMin...model.yAxisMax)
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
