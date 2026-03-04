import Foundation
import OSLog

import SQLiteData

import DokoSharing
import DokoTypes
import DokoLogging
import DokoSharing

import Vehicles
import VehicleInterface
import UndeterminedVehicle
import FordElectrics
import VwElectrics

extension SharedKey where Self == InMemoryKey<ConnectedVehicleInterface>.Default {
  public static var connectedVehicleInterface: Self {
    Self[.inMemory("DokoVehicleManager-ConnectedVehicleInterface"), default: UndeterminedVehicle()]
  }
}

public final class DokoVehicleManager: Sendable {
  private let logger = Logger(subsystem: "com.unchan.doko", category: "DokoVehicleManager")

  public static let shared = DokoVehicleManager()

  private func startAccessoryNameObservation() {
    @Shared(.connectedAccessory) var observedAccessoryName
    @Shared(.connectedVehicleInterface) var connectedVehicleInterface
    @Shared(.connectedVehicleModel) var connectedVehicleModel
    Task { [weak self] in
      guard let self else { return }
      var oldAccessoryName: String? = nil
      for await newAccessoryName in $observedAccessoryName.publisher.values {
        if Task.isCancelled { break }
        guard oldAccessoryName != newAccessoryName else { continue }
        if newAccessoryName == nil {
          $connectedVehicleInterface.withLock { $0 = setVehicleInterface(to: nil) }
          $connectedVehicleModel.withLock { $0 = nil }
        }
        oldAccessoryName = newAccessoryName
      }
    }
  }

  private func startVehicleInterfaceObservation() {
    @Shared(.connectedVehicleInterface) var connectedVehicleInterface
    @Shared(.connectedVehicleModel) var connectedVehicleModel
    Task { [weak self] in
      guard let self else { return }
      for await newInterface in $connectedVehicleInterface.publisher.values {
        if Task.isCancelled { break }
        self.logger.info("\(timestamp()) DVM: \(newInterface.name)")
        DokoLogging.shared.postLoggingResponse(.info("DVM: \(newInterface.name)"))
        $connectedVehicleModel.withLock { $0 = newInterface.vehicle?.model }
      }
    }
  }

  private init() {
    startAccessoryNameObservation()
    startVehicleInterfaceObservation()
  }

  public var connectedVehicle: Vehicle? {
    @Shared(.connectedVehicleInterface) var connectedVehicleInterface
    return connectedVehicleInterface.vehicle
  }

  public var vehicleIsConnected: Bool {
    @Shared(.connectedVehicleInterface) var connectedVehicleInterface
    return connectedVehicleInterface.vehicle != nil
  }

  public func addVehicle(newVehicle: Vehicle) -> Vehicle.ID? {
    @Dependency(\.defaultDatabase) var database
    let id: Vehicle.ID? = withErrorReporting {
      try database.write { db in
        let id = try Vehicle.upsert { newVehicle }.returning(\.id).fetchOne(db)
        return id
      }
    }
    return id
  }

  public func removeVehicle(vehicleID: Vehicle.ID) {
    @Dependency(\.defaultDatabase) var database
    @Shared(.connectedVehicleInterface) var connectedVehicleInterface
    if let connectedVehicle = connectedVehicleInterface.vehicle, connectedVehicle.id == vehicleID { return }
    withErrorReporting {
      try database.write { db in
        try Vehicle.where { $0.id.eq(vehicleID) }.delete().execute(db)
      }
    }
  }

  public func lookup(id: Vehicle.ID) -> Vehicle? {
    @FetchAll var vehicles: [Vehicle]
    guard let vehicle = vehicles.first(where: { $0.id == id }) else {
      return nil
    }
    return vehicle
  }
}

extension DokoVehicleManager {
  public enum VehicleType: CaseIterable {
    case undetermined
    case fordElectric
    case vwElectric
    public var description: String {
      switch self {
      case .undetermined: return "Undetermined"
      case .fordElectric: return "Ford Electric"
      case .vwElectric: return "VW Electric"
      }
    }
  }

  private func setVehicleInterface(to vehicle: Vehicle?) -> ConnectedVehicleInterface {
    self.logger.info("\(timestamp()) DVM.setVehicleInterface(\(vehicle?.makeModel ?? "nil"))")
    DokoLogging.shared.postLoggingResponse(.info("DVM.setVehicleInterface(\(vehicle?.makeModel ?? "nil"))"))
    guard let vehicle = vehicle else { return UndeterminedVehicle() }
    let vehicleInterface: ConnectedVehicleInterface = {
      switch lookupVehicleType(modelIdentifier: vehicle.modelIdentifier) {
      case .undetermined:
        return UndeterminedVehicle()
      case .fordElectric:
        return FordElectrics(vehicle: vehicle)
      case .vwElectric:
        return VwElectrics(vehicle: vehicle)
      }
    }()
    return vehicleInterface
  }

  public func setVin(vin: String?) -> Vehicle? {
    @FetchAll var vehicles: [Vehicle]
    @Shared(.connectedVehicleInterface) var connectedVehicleInterface
    guard let vin = vin else {
      self.logger.debug("\(timestamp()) DVM.setVin(nil)")
      $connectedVehicleInterface.withLock { $0 = setVehicleInterface(to: nil) }
      return nil
    }
    self.logger.debug("\(timestamp()) DVM.setVin(\(vin))")
    if let vehicle = vehicles.first(where: { $0.vin == vin }) {
      let vehicleType = lookupVehicleType(modelIdentifier: vehicle.modelIdentifier)
      self.logger.debug("\(timestamp()) DVM.setVin: \(vehicle.modelIdentifier.description), \(vehicleType.description)")
      $connectedVehicleInterface.withLock { $0 = setVehicleInterface(to: vehicle) }
      return vehicle
    }

    let newVehicle = Vehicle(vin: vin)
    guard let _ = addVehicle(newVehicle: newVehicle) else {
      DokoLogging.shared.postLoggingResponse(.error("DVM.setVin: could not add new vehicle"))
      return nil
    }
    let vehicleType = lookupVehicleType(modelIdentifier: newVehicle.modelIdentifier)
    self.logger.debug("\(timestamp()) DVM.setVin: \(newVehicle.modelIdentifier.description), \(vehicleType.description)")
    DokoLogging.shared.postLoggingResponse(.connect("DVM.setVin(\(vehicleType))"))
    $connectedVehicleInterface.withLock { $0 = setVehicleInterface(to: newVehicle) }
    return newVehicle
  }

  private func lookupVehicleType(modelIdentifier: ModelIdentifier) -> VehicleType {
    let vehicleTypeDictionary: [ModelIdentifier: VehicleType] = [
      .miTK1R: .fordElectric, .miTK1S: .fordElectric, .miTK2R: .fordElectric, .miTK3R: .fordElectric, .miTK3S: .fordElectric, .miTK4S: .fordElectric,
      .mi6W1E: .fordElectric, .mi6W3L: .fordElectric, .mi6W5L: .fordElectric, .miVW1E: .fordElectric, .miVW1B: .fordElectric,
      .miVW3L: .fordElectric, .miVW5L: .fordElectric, .miVW7L: .fordElectric,
      
      .mi5MPE: .vwElectric, .mi5NPE: .vwElectric, .miVMPE: .vwElectric, .miVNPE: .vwElectric, .miDMPE: .vwElectric,
      .miDNPE: .vwElectric, .miGMPE: .vwElectric, .miGNPE: .vwElectric, .miTMPE: .vwElectric, .miTNPE: .vwElectric,
      .miCMPE: .vwElectric, .miCNPE: .vwElectric, .miJSPE: .vwElectric
    ]
    guard let vehicleType = vehicleTypeDictionary[modelIdentifier] else {
      DokoLogging.shared.postLoggingResponse(.error("DVM.lookupVehicleType(.undetermined)"))
      return .undetermined
    }
    return vehicleType
  }
}
