import SwiftUI
import TipKit

import DokoVehicleManager
import DokoSchema
import DokoSharing
import DokoTypes
import CommonUI

extension SharedKey where Self == AppStorageKey<Vehicle.ID?>.Default {
  static var displayVehicleID: Self {
    Self[.appStorage("TripDisplayVehicleID"), default: nil]
  }
}

extension SharedKey where Self == AppStorageKey<DisplayPeriod>.Default {
  static var tripsDisplayPeriod: Self {
    Self[.appStorage("tripsDisplayPeriod"), default: DisplayPeriod.defaultDisplayPeriod]
  }
}

extension SharedKey where Self == AppStorageKey<DisplayPeriod>.Default {
  static var tripsCustomDisplayPeriod: Self {
    Self[.appStorage("tripsCustomDisplayPeriod"), default: DisplayPeriod.defaultCustomDisplayPeriod]
  }
}

@MainActor
@Observable
public final class TripsModel {
  @ObservationIgnored @FetchAll var vehicles: [Vehicle]
  @ObservationIgnored @FetchAll var locations: [Location]

  @ObservationIgnored @FetchAll(Trip.none) var trips: [Trip]

  @ObservationIgnored @FetchOne var tripStats: TripStats = TripStats()

  @ObservationIgnored @FetchOne(Trip.select { Stats.Columns(count: $0.count(filter: !$0.isDeleted)) })
  var myStats = Stats()
  @Selection
  struct Stats: Equatable {
    var count = 0
  }

  @ObservationIgnored @Shared(.displayVehicleID) var displayVehicleID

  @ObservationIgnored @Shared(.connectedAccessory) var connectedAccessory
  @ObservationIgnored @Shared(.connectedVehicleModel) var connectedVehicleModel
  @ObservationIgnored @Shared(.activeSession) var activeSession

  var meanTemperature: Double? = nil
  
  @ObservationIgnored @Shared(.tripsDisplayPeriod) var tripsDisplayPeriod
  @ObservationIgnored @Shared(.tripsCustomDisplayPeriod) var tripsCustomDisplayPeriod

  @ObservationIgnored @Shared(.metric) var metric
  @ObservationIgnored @Shared(.kWhPer100km) var kWhPer100km

  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored @Dependency(\.date.now) var now

  var vehicleButtonTitle: String = ""
  var vehicleButtonImage: String = ""
  
  let allVehiclesTitle: String = "All Vehicles"

  public init() {
    let (queryStart, queryEnd): (Date?, Date?) = {
      switch tripsDisplayPeriod {
      case .today:
        return setDisplayPeriod(.today)
      case .pastWeek:
        return setDisplayPeriod(.pastWeek)
      case .pastMonth:
        return setDisplayPeriod(.pastMonth)
      case .custom:
        return tripsDisplayPeriod.dateRange
      }
    }()
    
    setVehicleMenu(vehicleID: displayVehicleID)

    if let queryStart = queryStart, let queryEnd = queryEnd {
      _tripStats = FetchOne(
        wrappedValue: TripStats(),
        Trip
          .where { !$0.isDeleted }
          .where { $0.timeStart.gte(queryStart) && $0.timeStart.lt(queryEnd)  }
          .where {
            if let vehicleID = displayVehicleID {
              $0.vehicleID.eq(vehicleID)
            }
          }
          .select {
            TripStats.Columns(
              duration: $0.duration.sum(),
              distance: $0.distance.sum(),
              energy: $0.energy.sum(),
              meanTempWeighted: $0.weatherTempMeanWeighted.sum()
            )
          },
        animation: .default
      )
      if let meanTempWeighted = tripStats.meanTempWeighted,
         let meanTempDuration = tripStats.duration, meanTempDuration > 0.0 {
        meanTemperature = meanTempWeighted / meanTempDuration
      }

      _trips = FetchAll(
        Trip
          .where { !$0.isDeleted }
          .where { $0.timeStart.gte(queryStart) && $0.timeStart.lt(queryEnd) }
          .where {
            if let vehicleID = displayVehicleID {
              $0.vehicleID.eq(vehicleID)
            }
          }
          .order { $0.timeStart.desc() },
        animation: .default
      )
    }
  }
  
  @Selection
  struct TripStats: Equatable {
    var duration: Double?
    var distance: Double?
    var energy: Double?
    var meanTempWeighted: Double?
  }
  
  @discardableResult
  func setDisplayPeriod(_ newPeriod: DisplayPeriod) -> (Date?, Date?) {
    $tripsDisplayPeriod.withLock { $0 = newPeriod }
    if case .custom = newPeriod {
      $tripsCustomDisplayPeriod.withLock { $0 = newPeriod }
    }
    return newPeriod.dateRange
  }
  
  func setVehicleMenu(vehicleID: Vehicle.ID?) {
    $displayVehicleID.withLock { $0 = vehicleID }
    guard let vehicleID = vehicleID else {
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
      $displayVehicleID.withLock { $0 = nil }
    }
  }
  
  func vehicleButtonTapped(vehicleID: Vehicle.ID?) {
    setVehicleMenu(vehicleID: vehicleID)
  }
  
  func softDeleteTrip(_ tripID: Trip.ID) {
    withErrorReporting {
      try database.write { db in
        try Trip
          .find(tripID)
          .update { $0.deleted = #bind(now) }
          .execute(db)
      }
    }
  }
}

public struct TripsView: View {
  @Bindable var model: TripsModel
  @State private var path = NavigationPath()

  public init(model: TripsModel) {
    self.model = model
  }

  public var body: some View {
    NavigationStack(path: $path) {
      VStack(spacing: 0) {
        VStack(spacing: 8) {
          DisplayPeriodPicker(
            datePicker: Binding(
              get: { model.tripsDisplayPeriod },
              set: { model.setDisplayPeriod($0) }
            ),
            pickerName: "Display Period",
            customDisplayPeriod: model.tripsCustomDisplayPeriod
          )

          Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
              Menu {
                Button {
                  model.vehicleButtonTapped(vehicleID: nil)
                } label: {
                  Text(model.allVehiclesTitle)
                  Image(systemName: model.displayVehicleID == nil ? "checkmark" : "car.2")
                }
                ForEach(model.vehicles) { vehicle in
                  Button {
                    model.vehicleButtonTapped(vehicleID: vehicle.id)
                  } label: {
                    Text(vehicle.yearMakeModel)
                    if let currentVehicleID = model.displayVehicleID, currentVehicleID == vehicle.id {
                      Image(systemName: "checkmark")
                    } else {
                      Image(systemName: vehicle.truck ? "truck.pickup.side" : "car.side")
                    }
                  }
                }
              } label: {
                DokoGridButton(
                  color: .mint,
                  iconName: model.vehicleButtonImage,
                  title: model.vehicleButtonTitle
                ) {}
              }
            }
          }

          Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
            let tripCount = model.trips.count
            let duration: Duration = .seconds(model.tripStats.duration ?? 0.0)
            let metricDistance = Measurement(
              value: model.tripStats.distance ?? 0.0,
              unit: UnitLength.kilometers
            )
            let energyKWh = Measurement(value: (model.tripStats.energy ?? 0.0), unit: UnitEnergy.kilowattHours)
            let metricEfficiency = Measurement(
              value: energyKWh.value == 0.0 ? 0.0 : metricDistance.value / energyKWh.value,
              unit: UnitEnergyEfficiency.kilometersPerKilowattHour
            )

            let distance = metricDistance.converted(to: model.metric ? .kilometers : .miles)
            let energyEfficiency = metricEfficiency
              .converted(
                to:model.metric ? model.kWhPer100km ? .kilowattHoursPer100Kilometers : .kilometersPerKilowattHour : .milesPerKilowattHour
              )

            GridRow {
              DokoGridCount(
                color: .blue,
                value: "\(tripCount)",
                units: "",
                iconName: "bolt.car",
                title: "Trips"
              )

              DokoGridCount(
                color: .gray,
                value: duration.formatted(
                  .time(pattern: .hourMinute(padHourToLength: 2))
                ),
                units: "hh:mm",
                iconName: "clock",
                title: "Drive Time"
              )
            }

            GridRow {
              DokoGridCount(
                color: .yellow,
                value: String(format: "%.1f", distance.value as CVarArg),
                units: distance.unit.symbol,
                iconName: "road.lanes",
                title: "Distance"
              )
              
              if let meanTemperaturePeriodMetric = model.meanTemperature {
                let meanTemperaturePeriod = Measurement(value: meanTemperaturePeriodMetric, unit: UnitTemperature.celsius)
                  .converted(to: model.metric ? .celsius : .fahrenheit)
                let (meanTemperaturePeriodColor, meanTemperaturePeriodIcon) = {
                  if meanTemperaturePeriodMetric <= 4 { return (Color.blue, "thermometer.low") }
                  if meanTemperaturePeriodMetric < 30 { return (Color.green,"thermometer.medium") }
                  return (Color.red, "thermometer.high")
                }()
                DokoGridCount(
                  color: meanTemperaturePeriodColor,
                  value: String(format: "%.0f", meanTemperaturePeriod.value as CVarArg),
                  units: meanTemperaturePeriod.unit.symbol,
                  iconName: meanTemperaturePeriodIcon,
                  title: "Mean Temp"
                )
              } else {
                let meanTemperaturePeriod = Measurement(value: 0, unit: UnitTemperature.celsius)
                  .converted(to: model.metric ? .celsius : .fahrenheit)
                DokoGridCount(
                  color: .green,
                  value: "-",
                  units: meanTemperaturePeriod.unit.symbol,
                  iconName: "thermometer.medium",
                  title: "Mean Temp"
                )
              }
            }

            GridRow {
              DokoGridCount(
                color: .red,
                value: String(format: "%.1f", energyKWh.value as CVarArg),
                units: energyKWh.unit.symbol,
                iconName: "bolt.circle.fill",
                title: "Energy Used"
              )

              DokoGridCount(
                color: .green,
                value: String(format: "%.1f", energyEfficiency.value as CVarArg),
                units: energyEfficiency.unit.symbol,
                iconName: "powermeter",
                title: "Efficiency"
              )
            }
          }
        }
        .padding(.horizontal)

        List {
          TipView(TripDetailsTip())
          ForEach(model.trips.enumerated(), id: \.element.id) { index, trip in
            Button {
              path.append(Destination.tripDetail(trip))
            } label: {
              TripRow(trip: trip)
                .rowFormatter(index)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                  Button(role: .confirm) {
                    model.softDeleteTrip(trip.id)
                  } label: {
                    HStack {
                      Image(systemName: "trash")
                      Text("Delete")
                    }      }
                  .tint(.red)
                }
              Spacer()
            }
            .buttonStyle(.borderless)
          }
        }
        .listStyle(.plain)
      }
      .sessionToolbar(
        connectedAccessory: model.connectedAccessory,
        connectedVehicleModel: model.connectedVehicleModel,
        activeSession: model.activeSession
      )
      .navigationDestination(for: Destination.self) { destination in
        switch destination {
        case .tripDetail(let trip):
          TripDetailView(
            model: TripDetailModel(tripID: trip.id)
          )
        }
      }
      .onChange(of: model.vehicles.count) { oldCount, newCount in
        if newCount < oldCount {
          path = NavigationPath()
        }
      }
    }
  }
  
  enum Destination: Hashable {
    case tripDetail(Trip)
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
    @Shared(.connectedAccessory) var connectedAccessory
    @Shared(.connectedVehicleModel) var connectedVehicleModel
    @Shared(.activeSession) var activeSession
    $connectedAccessory.withLock { $0 = nil }
    $connectedVehicleModel.withLock { $0 = nil }
    $activeSession.withLock { $0 =  nil }
  }
  NavigationStack {
    TripsView(
      model: TripsModel()
    )
    .preferredColorScheme(.dark)
  }
}

#Preview("With Toolbar") {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()

    @Shared(.connectedAccessory) var connectedAccessory
    @Shared(.connectedVehicleModel) var connectedVehicleModel
    @Shared(.activeSession) var activeSession
    $connectedAccessory.withLock { $0 = "OBDLink MX+" }
    $connectedVehicleModel.withLock { $0 = "2024 Ford Mach-E GT" }
    $activeSession.withLock { $0 =  .trip }
  }
  NavigationStack {
    TripsView(
      model: TripsModel()
    )
    .preferredColorScheme(.dark)
  }
}
