import SwiftUI
import TipKit

import DokoVehicleManager
import DokoSchema
import DokoSharing
import CommonUI

extension SharedKey where Self == AppStorageKey<Vehicle.ID?>.Default {
  static var displayVehicleID: Self {
    Self[.appStorage("ChargesDisplayVehicleID"), default: nil]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var showAcCharges: Self {
    Self[.appStorage("chargesShowAcCharges"), default: true]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var showDcCharges: Self {
    Self[.appStorage("chargesShowDcCharges"), default: true]
  }
}

extension SharedKey where Self == AppStorageKey<DisplayPeriod>.Default {
  static var chargesDisplayPeriod: Self {
    Self[.appStorage("chargesDisplayPeriod"), default: DisplayPeriod.defaultDisplayPeriod]
  }
}

extension SharedKey where Self == AppStorageKey<DisplayPeriod>.Default {
  static var chargesCustomDisplayPeriod: Self {
    Self[.appStorage("chargesCustomDisplayPeriod"), default: DisplayPeriod.defaultCustomDisplayPeriod]
  }
}

@MainActor
@Observable
public final class ChargesModel {
  @ObservationIgnored @FetchAll var vehicles: [Vehicle]
  @ObservationIgnored @FetchAll var locations: [Location]

  @ObservationIgnored @FetchAll(Charge.none) var charges: [Charge]
  @ObservationIgnored @FetchOne var chargeStats: ChargeStats = ChargeStats()

  @ObservationIgnored @FetchOne(Charge.select { Stats.Columns(count: $0.count(filter: !$0.isDeleted)) })
  var myStats = Stats()
  @Selection
  struct Stats: Equatable {
    var count = 0
  }

  @ObservationIgnored @Shared(.displayVehicleID) var displayVehicleID

  @ObservationIgnored @Shared(.connectedAccessoryName) var connectedAccessoryName
  @ObservationIgnored @Shared(.connectedVehicleModel) var connectedVehicleModel
  @ObservationIgnored @Shared(.activeSession) var activeSession

  @ObservationIgnored @Shared(.showAcCharges) var showAcCharges
  @ObservationIgnored @Shared(.showDcCharges) var showDcCharges

  @ObservationIgnored @Shared(.chargesDisplayPeriod) var displayPeriod
  @ObservationIgnored @Shared(.chargesCustomDisplayPeriod) var customDisplayPeriod

  @ObservationIgnored @Shared(.metric) var metric

  @ObservationIgnored @Dependency(\.defaultDatabase) var database
  @ObservationIgnored @Dependency(\.date.now) var now

  var vehicleButtonTitle: String = ""
  var vehicleButtonImage: String = ""

  let allVehiclesTitle: String = "All Vehicles"

  public init() {
    let (queryStart, queryEnd): (Date?, Date?) = {
      switch displayPeriod {
      case .today:
        return setDisplayPeriod(.today)
      case .pastWeek:
        return setDisplayPeriod(.pastWeek)
      case .pastMonth:
        return setDisplayPeriod(.pastMonth)
      case .custom:
        return displayPeriod.dateRange
      }
    }()

    setVehicleMenu(vehicleID: displayVehicleID)

    if let queryStart = queryStart, let queryEnd = queryEnd {
      _chargeStats = FetchOne(
        wrappedValue: ChargeStats(),
        Charge
          .where { !$0.isDeleted }
          .where { $0.timeStart.gte(queryStart) && $0.timeStart.lt(queryEnd) }
          .where {
            if showAcCharges && showDcCharges { !$0.isNoCharge }
            else if showAcCharges { $0.isAcCharge }
            else if showDcCharges {  $0.isDcCharge }
            else { $0.isNoCharge }
          }
          .where { if let vehicleID = displayVehicleID { $0.vehicleID.eq(vehicleID) } }
          .select {
            ChargeStats.Columns(
              acCount: $0.count(filter: $0.chargerType.eq(Charge.ChargerType.ac)),
              dcCount: $0.count(filter: $0.chargerType.eq(Charge.ChargerType.dc)),
              acDuration: $0.duration.sum(filter: $0.chargerType.eq(Charge.ChargerType.ac)),
              dcDuration: $0.duration.sum(filter: $0.chargerType.eq(Charge.ChargerType.dc)),
              acEnergy: $0.energy.sum(filter: $0.chargerType.eq(Charge.ChargerType.ac)),
              dcEnergy: $0.energy.sum(filter: $0.chargerType.eq(Charge.ChargerType.dc))
            )
          },
        animation: .default
      )
      
      _charges = FetchAll(
        Charge
          .where { !$0.isDeleted }
          .where { $0.timeStart.gte(queryStart) && $0.timeStart.lt(queryEnd) }
          .where {
            if showAcCharges && showDcCharges { !$0.isNoCharge }
            else if showAcCharges { $0.isAcCharge }
            else if showDcCharges {  $0.isDcCharge }
            else { $0.isNoCharge }
          }
          .where { if let vehicleID = displayVehicleID { $0.vehicleID.eq(vehicleID) } }
          .order { $0.timeStart.desc() },
        animation: .default
      )
    }
  }

  @Selection
  struct ChargeStats: Equatable {
    var acCount: Int = 0
    var dcCount: Int = 0
    var acDuration: Double?
    var dcDuration: Double?
    var acEnergy: Double?
    var dcEnergy: Double?
  }

  @discardableResult
  func setDisplayPeriod(_ newPeriod: DisplayPeriod) -> (Date?, Date?) {
    $displayPeriod.withLock { $0 = newPeriod }
    if case .custom = newPeriod {
      $customDisplayPeriod.withLock { $0 = newPeriod }
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

  func acChargingButtonTapped() {
    $showAcCharges.withLock { $0.toggle() }
  }

  func dcChargingButtonTapped() {
    $showDcCharges.withLock { $0.toggle() }
  }
  
  func softDeleteCharge(_ chargeID: Charge.ID, undelete: Bool = false) {
    withErrorReporting {
      try database.write { db in
        try Charge.find(chargeID).update { $0.deleted = undelete ? nil : now }.execute(db)
      }
    }
  }
}

public struct ChargesView: View {
  @Bindable var model: ChargesModel
  @State private var path = NavigationPath()
  @State private var isAddingCharge = false

  public init(model: ChargesModel) {
    self.model = model
  }

  public var body: some View {
    NavigationStack(path: $path) {
      VStack(spacing: 0) {
        VStack(spacing: 8) {
          DisplayPeriodPicker(
            datePicker: Binding(
              get: { model.displayPeriod },
              set: { model.setDisplayPeriod($0) }
            ),
            pickerName: "Display Period",
            customDisplayPeriod: model.customDisplayPeriod
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
            let acChargeCount = model.chargeStats.acCount
            let dcChargeCount = model.chargeStats.dcCount
            let acDuration: Duration = .seconds(model.chargeStats.acDuration ?? 0.0)
            let dcDuration: Duration = .seconds(model.chargeStats.dcDuration ?? 0.0)
            let acEnergy = Measurement(
              value: model.chargeStats.acEnergy ?? 0.0,
              unit: UnitEnergy.kilowattHours
            )
            let dcEnergy = Measurement(
              value: model.chargeStats.dcEnergy ?? 0.0,
              unit: UnitEnergy.kilowattHours
            )

            GridRow {
              DokoGridButton(
                color: .orange,
                iconName: "powerplug",
                title: "AC"
              ) {
                model.acChargingButtonTapped()
              }
              .opacity(model.showAcCharges ? DesignTokens.Opacity.full : DesignTokens.Opacity.subtle)

              DokoGridButton(
                color: .green,
                iconName: "ev.charger",
                title: "DC"
              ) {
                model.dcChargingButtonTapped()
              }
              .opacity(model.showDcCharges ? DesignTokens.Opacity.full : DesignTokens.Opacity.subtle)
            }

            GridRow {
              DokoGridCount(
                color: .orange,
                value: "\(acChargeCount)",
                units: "",
                iconName: "bolt.car",
                title: "Charges"
              )
              .opacity(model.showAcCharges ? DesignTokens.Opacity.full : DesignTokens.Opacity.subtle)

              DokoGridCount(
                color: .green,
                value: "\(dcChargeCount)",
                units: "",
                iconName: "bolt.car",
                title: "Charges"
              )
              .opacity(model.showDcCharges ? DesignTokens.Opacity.full : DesignTokens.Opacity.subtle)
            }

            GridRow {
              DokoGridCount(
                color: .orange,
                value: acDuration.formatted(
                  .time(pattern: .hourMinute(padHourToLength: 2))
                ),
                units: "hh:mm",
                iconName: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted",
                title: "Time"
              )
              .opacity(model.showAcCharges ? DesignTokens.Opacity.full : DesignTokens.Opacity.subtle)

              DokoGridCount(
                color: .green,
                value: dcDuration.formatted(
                  .time(pattern: .hourMinute(padHourToLength: 2))
                ),
                units: "hh:mm",
                iconName: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted",
                title: "Time"
              )
              .opacity(model.showDcCharges ? DesignTokens.Opacity.full : DesignTokens.Opacity.subtle)
            }

            GridRow {
              DokoGridCount(
                color: .orange,
                value: String(format: "%.0f", acEnergy.value as CVarArg),
                units: acEnergy.unit.symbol,
                iconName: "bolt.batteryblock",
                title: "Energy"
              )
              .opacity(model.showAcCharges ? DesignTokens.Opacity.full : DesignTokens.Opacity.subtle)

              DokoGridCount(
                color: .green,
                value: String(format: "%.0f", dcEnergy.value as CVarArg),
                units: dcEnergy.unit.symbol,
                iconName: "bolt.batteryblock",
                title: "Energy"
              )
              .opacity(model.showDcCharges ? DesignTokens.Opacity.full : DesignTokens.Opacity.subtle)
            }
          }
        }
        .padding(.horizontal)

        List {
          TipView(ChargeDetailsTip())
          ForEach(model.charges.enumerated(), id: \.element.id) { index, charge in
            Button {
              path.append(Destination.chargeDetail(charge))
            } label: {
              ChargeRow(charge: charge)
                .rowFormatter(index)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                  Button(role: .confirm) {
                    model.softDeleteCharge(charge.id)
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
      .sheet(isPresented: $isAddingCharge) {
        NavigationStack {
          AddChargeFormView(
            model: AddChargeFormModel(vehicleID: model.displayVehicleID)
          )
          .navigationTitle("Add Charge")
          .navigationBarTitleDisplayMode(.inline)
          .presentationDetents([.large])
        }
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            isAddingCharge = true
          } label: {
            Image(systemName: "plus")
          }
        }
      }
      .sessionToolbar(
        connectedAccessoryName: model.connectedAccessoryName,
        connectedVehicleModel: model.connectedVehicleModel,
        activeSession: model.activeSession
      )
      .navigationDestination(for: Destination.self) { destination in
        switch destination {
        case .chargeDetail(let charge):
          ChargeDetailView(
            model: ChargeDetailModel(chargeID: charge.id)
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
    case chargeDetail(Charge)
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    ChargesView(
      model: ChargesModel()
    )
    .preferredColorScheme(.dark)
  }
}
