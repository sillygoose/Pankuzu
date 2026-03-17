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
import FordMachE
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
    @Shared(.connectedAccessoryName) var observedAccessoryName
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
        DokoLogging.shared.postLoggingResponse(.connect("\(newInterface.name)"))
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
  private func setVehicleInterface(to vehicle: Vehicle?) -> ConnectedVehicleInterface {
    self.logger.info("\(timestamp()) DVM.setVehicleInterface(\(vehicle?.makeModel ?? "nil"))")
    DokoLogging.shared.postLoggingResponse(.info("DVM.setVehicleInterface(\(vehicle?.makeModel ?? "nil"))"))
    guard let vehicle = vehicle else { return UndeterminedVehicle() }
    let vehicleInterface: ConnectedVehicleInterface = {
      switch vehicle.vehicleType {
      case .undetermined:
        return UndeterminedVehicle()
      case .fordElectric:
        return FordElectrics(vehicle: vehicle)
      case .fordMachE:
        return FordMachE(vehicle: vehicle)
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
      self.logger.debug("\(timestamp()) DVM.setVin: \(vehicle.model), \(vehicle.vehicleType.description)")
      $connectedVehicleInterface.withLock { $0 = setVehicleInterface(to: vehicle) }
      return vehicle
    }

    let newVehicle = Vehicle(vin: vin)
    guard let _ = addVehicle(newVehicle: newVehicle) else {
      DokoLogging.shared.postLoggingResponse(.error("DVM.setVin: could not add new vehicle"))
      return nil
    }
    self.logger.debug("\(timestamp()) DVM.setVin: \(newVehicle.model), \(newVehicle.vehicleType.description)")
    DokoLogging.shared.postLoggingResponse(.connect("DVM.setVin(\(newVehicle.vehicleType))"))
    $connectedVehicleInterface.withLock { $0 = setVehicleInterface(to: newVehicle) }
    return newVehicle
  }
}
