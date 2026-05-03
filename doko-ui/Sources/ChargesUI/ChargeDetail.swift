import Foundation
import SwiftUI
import TipKit

import DokoSharing
import DokoLocationManager
import DokoVehicleManager
import DokoSchema
import DokoTypes
import DokoExtensions
import VehiclesUI
import LocationsUI
import CommonUI

@MainActor @Observable public final class ChargeDetailModel {
  public enum Destination: Identifiable {
    case editChargeForm(Charge)
    case editLocationForm(Location)
    case editVehicleForm(Vehicle)
    case chargeLocationMap
    case powerChart
    case energyAddedChart
    case rangeAddedChart
    case stateOfChargeChart
    case batteryTemperatureChart
    case couplerTemperatureChart
    case stateOfHealthChart
    
    public var id: String {
      switch self {
      case .editChargeForm(let charge):
        return "editChargeForm-\(charge.id)"
      case .editLocationForm(let location):
        return "editLocationForm-\(location.id)"
      case .editVehicleForm(let vehicle):
        return "editVehicleForm-\(vehicle.id)"
      case .chargeLocationMap:
        return "chargeLocationMap"
      case .powerChart:
        return "powerChart"
      case .energyAddedChart:
        return "energyAddedChart"
      case .rangeAddedChart:
        return "rangeAddedChart"
      case .stateOfChargeChart:
        return "stateOfChargeChart"
      case .batteryTemperatureChart:
        return "batteryTemperatureChart"
      case .couplerTemperatureChart:
        return "couplerTemperatureChart"
      case .stateOfHealthChart:
        return "stateOfHealthChart"
      }
    }
  }
  
  var destination: Destination?
  
  @ObservationIgnored @FetchOne(Charge.none) var charge
  @ObservationIgnored @FetchOne(ChargeHistory.none) var chargeHistory
  @ObservationIgnored @FetchAll var locations: [Location]
  @ObservationIgnored @Shared(.appSettings) var appSettings
  
  var chargeLocation: Location = .unexpectedLocation
  var vehicle: Vehicle?
  var maximumPower: Double?
  
  public init(
    destination: Destination? = nil,
    chargeID: Charge.ID
  ) {
    self.destination = destination
    _charge = FetchOne(Charge.find(chargeID))
    if let charge = self.charge {
      self.vehicle = DokoVehicleManager.shared.lookup(id: charge.vehicleID)
      self.chargeLocation = DokoLocationManager.shared.lookup(id: charge.locationID)
      _chargeHistory = FetchOne(ChargeHistory.find(charge.id))
      self.maximumPower = chargeHistory?.batteryPower.map(\.datapoint).max()
    }
  }
}

public struct ChargeDetailView: View {
  @Bindable var model: ChargeDetailModel
  
  public init(model: ChargeDetailModel) {
    self.model = model
  }
  
  public var body: some View {
    let charge = model.charge ?? Charge.honestEmptyCharge
    let duration: Duration = .seconds(charge.duration)
    let odometer = Measurement(value: charge.odometer, unit: UnitLength.kilometers)
      .converted(to: model.appSettings.metric ? .kilometers : .miles)
    let peakPower = Measurement(value: model.maximumPower ?? 0.0, unit: UnitPower.kilowatts)
    
    ScrollView {
      TipView(EditChargeDetailTip())
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          GridButton(color: .blue, symbolName: "map.fill", title: "Map") {
            model.destination = .chargeLocationMap
          }
          
          GridButton(
            color: .green,
            symbolName: "chart.xyaxis.line",
            title: "Power"
          ) {
            model.destination = .powerChart
          }
          
          GridButton(
            color: .yellow,
            symbolName: "car",
            title: model.vehicle?.name ?? (model.vehicle?.model ?? "Missing Vehicle")
          ) {
            if let vehicle = model.vehicle {
              model.destination = .editVehicleForm(vehicle)
            }
          }
        }
      }
      
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        Section {
          Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
              GridLocation(
                color: charge.chargerType == .ac ? .purple : .green,
                placeName: model.chargeLocation.placeName,
                cityState: model.chargeLocation.cityState,
                label: charge.chargerType == .ac ? "AC" : "DCFC",
                symbolName: charge.chargerType == .ac ? "powerplug" : "ev.charger"
              ) {
                model.destination = .editLocationForm(model.chargeLocation)
              }
            }
          }
        }
      }
      
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
        GridValue(
          color: .yellow,
          value: String(format: "%.1f", odometer.value),
          units: odometer.unit.symbol,
          symbolName: "gauge.open.with.lines.needle.33percent",
          title: "Odometer"
        )
        
        GridValue(
          color: .gray,
          value: duration.formatted(.time(pattern: .hourMinute(padHourToLength: 2))),
          units: "hh:mm",
          symbolName: "clock",
          title: "Duration"
        )
        
        if let energy = charge.energy {
          let energyAdded = Measurement(value: energy, unit: UnitEnergy.kilowattHours)
          let displayEnergy = abs(energyAdded.value) < 0.05 ? 0.0 : energyAdded.value
          GridValueButton(
            color: .blue,
            value: String(format: "%.1f", displayEnergy),
            units: energyAdded.unit.symbol,
            symbolName: "bolt.circle.fill",
            title: "Energy Added"
          ) {
            model.destination = .energyAddedChart
          }
          
          GridValue(
            color: .red,
            value: String(format: "%.1f", peakPower.value),
            units: peakPower.unit.symbol,
            symbolName: "bolt",
            title: "Peak Power"
          )
        }
        
        if let rawStateOfChargeStart = charge.stateOfChargeStart {
          let (stateOfChargeStartColor, stateOfChargeStartIcon) = {
            if rawStateOfChargeStart < 5 { return (Color.red, "battery.0percent") }
            if rawStateOfChargeStart < 30 { return (Color.yellow, "battery.25percent") }
            if rawStateOfChargeStart < 55 { return (Color.green, "battery.50percent") }
            if rawStateOfChargeStart < 80 { return (Color.green, "battery.75percent") }
            return (Color.green, "battery.100percent")
          }()
          let stateOfChargeStart = Measurement(value: rawStateOfChargeStart, unit: UnitPercent.percent)
          GridValueButton(
            color: stateOfChargeStartColor,
            value: String(format: "%.0f", stateOfChargeStart.value),
            units: stateOfChargeStart.unit.symbol,
            symbolName: stateOfChargeStartIcon,
            title: "Starting SoC"
          ) {
            model.destination = .stateOfChargeChart
          }
        }

        if let rawStateOfChargeEnd = charge.stateOfChargeEnd {
          let (stateOfChargeEndColor, stateOfChargeEndIcon) = {
            if rawStateOfChargeEnd < 5 { return (Color.red, "battery.0percent") }
            if rawStateOfChargeEnd < 30 { return (Color.yellow, "battery.25percent") }
            if rawStateOfChargeEnd < 55 { return (Color.green, "battery.50percent") }
            if rawStateOfChargeEnd < 80 { return (Color.green, "battery.75percent") }
            return (Color.green, "battery.100percent")
          }()
          let stateOfChargeEnd = Measurement(value: rawStateOfChargeEnd, unit: UnitPercent.percent)
          GridValueButton(
            color: stateOfChargeEndColor,
            value: String(format: "%.0f", stateOfChargeEnd.value),
            units: stateOfChargeEnd.unit.symbol,
            symbolName: stateOfChargeEndIcon,
            title: "Ending SoC"
          ) {
            model.destination = .stateOfChargeChart
          }
        }

        if let rawBatteryTempStart = charge.batteryTempStart {
          let (batteryTempStartColor, batteryTempStartIcon) = {
            if rawBatteryTempStart < 5 { return (Color.blue, "batteryblock.stack.badge.snowflake") }
            if rawBatteryTempStart < 50 { return (Color.gray, "batteryblock.stack") }
            return (Color.red, "batteryblock.stack.trianglebadge.exclamationmark")
          }()
          let batteryTempStart = Measurement(value: rawBatteryTempStart, unit: UnitTemperature.celsius)
            .converted(to: model.appSettings.metric ? .celsius : .fahrenheit)
          GridValueButton(
            color: batteryTempStartColor,
            value: String(format: "%.0f", batteryTempStart.value),
            units: batteryTempStart.unit.symbol,
            symbolName: batteryTempStartIcon,
            title: "Start Battery"
          ) {
            model.destination = .batteryTemperatureChart
          }
        }

        if let rawBatteryTempEnd = charge.batteryTempEnd {
          let (batteryTempEndColor, batteryTempEndIcon) = {
            if rawBatteryTempEnd < 5 { return (Color.blue, "batteryblock.stack.badge.snowflake") }
            if rawBatteryTempEnd < 50 { return (Color.gray, "batteryblock.stack") }
            return (Color.red, "batteryblock.stack.trianglebadge.exclamationmark")
          }()
          let batteryTempEnd = Measurement(value: rawBatteryTempEnd, unit: UnitTemperature.celsius)
            .converted(to: model.appSettings.metric ? .celsius : .fahrenheit)
          GridValueButton(
            color: batteryTempEndColor,
            value: String(format: "%.0f", batteryTempEnd.value),
            units: batteryTempEnd.unit.symbol,
            symbolName: batteryTempEndIcon,
            title: "Ending Battery"
          ) {
            model.destination = .batteryTemperatureChart
          }
        }

        if let rawCouplerTempStart = charge.couplerTempStart {
          let (couplerTempStartColor, couplerTempStartIcon) = {
            if rawCouplerTempStart < 5 { return (Color.blue, "ev.plug.dc.ccs2") }
            if rawCouplerTempStart < 50 { return (Color.yellow, "ev.plug.dc.ccs2") }
            return (Color.red, "ev.plug.dc.ccs2")
          }()
          let couplerTempStart = Measurement(value: rawCouplerTempStart, unit: UnitTemperature.celsius)
            .converted(to: model.appSettings.metric ? .celsius : .fahrenheit)
          GridValueButton(
            color: couplerTempStartColor,
            value: String(format: "%.0f", couplerTempStart.value),
            units: couplerTempStart.unit.symbol,
            symbolName: couplerTempStartIcon,
            title: "Starting Coupler"
          ) {
            model.destination = .couplerTemperatureChart
          }
        }

        if let rawCouplerTempEnd = charge.couplerTempEnd {
          let (couplerTempEndColor, couplerTempEndIcon) = {
            if rawCouplerTempEnd < 5 { return (Color.blue, "ev.plug.dc.ccs2") }
            if rawCouplerTempEnd < 50 { return (Color.yellow, "ev.plug.dc.ccs2") }
            return (Color.red, "ev.plug.dc.ccs2")
          }()
          let couplerTempEnd = Measurement(value: rawCouplerTempEnd, unit: UnitTemperature.celsius)
            .converted(to: model.appSettings.metric ? .celsius : .fahrenheit)
          GridValueButton(
            color: couplerTempEndColor,
            value: String(format: "%.0f", couplerTempEnd.value),
            units: couplerTempEnd.unit.symbol,
            symbolName: couplerTempEndIcon,
            title: "Ending Coupler"
          ) {
            model.destination = .couplerTemperatureChart
          }
        }
        if let rawDistanceToEmptyStart = charge.distanceToEmptyStart, let rawDistanceToEmptyEnd = charge.distanceToEmptyEnd {
          let rangeAdded = Measurement(value: rawDistanceToEmptyEnd - rawDistanceToEmptyStart, unit: UnitLength.kilometers)
            .converted(to: model.appSettings.metric ? .kilometers : .miles)
          GridValueButton(
            color: Color.blue,
            value: String(format: "%+.0f", rangeAdded.value),
            units: rangeAdded.unit.symbol,
            symbolName: "road.lanes.curved.right",
            title: "Range Added"
          ) {
            model.destination = .rangeAddedChart
          }
        }

        if let rawBatteryStateOfHealth = charge.batteryStateOfHealth {
          let batteryStateOfHealth = Measurement(value: rawBatteryStateOfHealth, unit: UnitPercent.percent)
          let batteryStateOfHealthColor = {
            if batteryStateOfHealth.value < 80 { return Color.red }
            if batteryStateOfHealth.value < 90 { return Color.yellow }
            return Color.green
          }()
          GridValueButton(
            color: batteryStateOfHealthColor,
            value: String(format: "%.0f", batteryStateOfHealth.value),
            units: batteryStateOfHealth.unit.symbol,
            symbolName: "batteryblock.stack.fill",
            title: "State of Health"
          ) {
            model.destination = .stateOfHealthChart
          }
        }
      }
      .padding([.bottom], 10)
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Edit") {
          model.destination = .editChargeForm(charge)
        }
      }
    }
    .navigationTitle(
      "\(charge.timeStart.formatted(date: .numeric, time: .shortened))"
    )
    .navigationBarTitleDisplayMode(.inline)
    .sheet(item: $model.destination) { destination in
      switch destination {
      case .editChargeForm(let charge):
        NavigationStack {
          ChargeFormView(
            model: ChargeFormModel(
              charge: Charge.Draft(charge)
            )
          )
          .navigationTitle("Edit Charge")
          .navigationBarTitleDisplayMode(.inline)
          .presentationDetents([.medium])
        }
        
      case .editLocationForm(let location):
        NavigationStack {
          LocationFormView(
            model: LocationFormModel(
              location: Location.Draft(location)
            )
          )
          .presentationDetents([.large])
        }
        
      case .editVehicleForm(let vehicle):
        NavigationStack {
          VehicleFormView(
            model: VehicleFormModel(
              vehicle: Vehicle.Draft(vehicle)
            )
          )
          .presentationDetents([.medium])
        }
        
      case .chargeLocationMap:
        NavigationStack {
          ChargeDetailMapView(
            model: ChargeDetailMapModel(
              charge: charge
            )
          )
          .presentationDetents([.large])
        }
        
      case .powerChart:
        NavigationStack {
          ChargeDetailPowerChartView(
            model: ChargeDetailPowerChartModel(
              charge: charge
            )
          )
          .presentationDetents([.medium])
        }
        
      case .energyAddedChart:
        NavigationStack {
          ChargeDetailEnergyView(
            model: ChargeDetailEnergyModel(
              charge: charge
            )
          )
          .presentationDetents([.medium])
        }
        
      case .rangeAddedChart:
        NavigationStack {
          ChargeDetailRangeAddedView(
            model: ChargeDetailRangeAddedModel(
              charge: charge
            )
          )
          .presentationDetents([.medium])
        }
        
      case .batteryTemperatureChart:
        NavigationStack {
          ChargeDetailBatteryTemperatureView(
            model: ChargeDetailBatteryTemperatureModel(
              charge: charge
            )
          )
          .presentationDetents([.medium])
        }
        
      case .couplerTemperatureChart:
        NavigationStack {
          ChargeDetailCouplerTempChartView(
            model: ChargeDetailCouplerTempChartModel(
              charge: charge
            )
          )
          .presentationDetents([.medium])
        }
        
      case .stateOfChargeChart:
        NavigationStack {
          ChargeDetailStateOfChargeView(
            model: ChargeDetailStateOfChargeModel(
              charge: charge
            )
          )
          .presentationDetents([.medium])
        }
        
      case .stateOfHealthChart:
        NavigationStack {
          SoHHistoryView(
            model: SoHHistoryModel(
              vehicleID: charge.vehicleID,
              currentID: charge.id
            )
          )
          .presentationDetents([.medium])
        }
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  @FetchAll() var charges: [Charge]
  NavigationStack {
    let _ = try? Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.applicationDefault)])
    ChargeDetailView(
      model: ChargeDetailModel(
        chargeID: charges.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
