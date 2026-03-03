import OSLog

import DokoTypes
import DokoLogging
import VehicleInterface
import ObdLinkCore
import Vehicles

public actor FordElectrics: ConnectedVehicleInterface {
  let logger = Logger(subsystem: "com.unchan.doko", category: "FordElectrics")

  nonisolated public let vehicle: Vehicle?
  nonisolated public let name: String = "FordElectrics"

  public var batteryPower: Double = 0.0
  public var batteryEnergy: Double = 0.0
  public var lastEnergyUpdateTime: Date?
  public var lastBatteryPower: Double?

  public var meanTemperatureSum: Double = 0.0
  public var meanTemperatureCount: Int = 0

  public init(vehicle: Vehicle?) {
    self.vehicle = vehicle
  }

  public func vehicleObdCommand(_ command: ObdCommand) async -> String? {
    typealias CommandLookupDictionary = [ObdCommand: String]
    let commandLookupDictionary: CommandLookupDictionary = [
//      .extendedDiagnosticSession:       "1003",
//      .testerPresent:                   "3E80",

      .stpx0:                           "STPX h:7E0, d:1001, r:1",
      .stpx1:                           "STPX h:7E0, d:1003, r:1",
      .stpx2:                           "STPX h:7E2, d:1001, r:1",
      .stpx3:                           "STPX h:7E2, d:1003, r:1",
      .stpx4:                           "STPX h:7E4, d:1001, r:1",
      .stpx5:                           "STPX h:7E4, d:1003, r:1",
      .stpx6:                           "STPX h:7E6, d:1001, r:1",
      .stpx7:                           "STPX h:7E6, d:1003, r:1",

      .gearSelected:                    "STPX h:7E2, d:221E12",

      .energyToEmpty:                   "STPX h:7E4, d:224848",
      .stateOfCharge:                   "STPX h:7E4, d:224845",
      .stateOfHealth:                   "STPX h:7E4, d:22490C",
      .batteryTemperature:              "STPX h:7E4, d:224800",
      .batteryVoltage:                  "STPX h:7E4, d:22480D",
      .batteryCurrent:                  "STPX h:7E4, d:2248F9",

      .acChargerStatus:                 "STPX h:7E4, d:22484F",
      .acChargerCouplerTemperature:     "STPX h:7E2, d:224888",
      .dcChargerStatus:                 "STPX h:7E4, d:22489E",
      .dcChargerCouplerTemperature:     "STPX h:7E2, d:224897",

      .odometer:                        "01A6",

      .position:                        "",
      .weather:                         "",
    ]
    guard let obdLinkCommand = commandLookupDictionary[command] else {
      DokoLogging.shared.postLoggingResponse(.error("FE.vehicleObdCommand(\(command.description)): dictionary empty"))
      return nil
    }
#if DEBUG
//    @Shared(.simIdle) var simIdle
//    if simIdle {
//      if command == .extendedDiagnosticSession { return "" }
//      if command == .testerPresent { return "" }
//    }
#endif
    return obdLinkCommand
  }

  public func translateDokoCommandPacket(using packetType: DokoPacketType) async -> ObdCommandPacket? {
    switch packetType {
    case .vehicleCapabilities:
      return ObdCommandPacket(type: .vehicleCapabilities, commands: [
//        .extendedDiagnosticSession,
        .stpx0, .stpx1, .stpx2, .stpx3, .stpx4, .stpx5, .stpx6, .stpx7,
        .odometer
      ])
//    case .testerPresent:
//      return ObdCommandPacket(type: .testerPresent, commands: [
//        .testerPresent
//      ])

    case .idle:
      return ObdCommandPacket(type: .idle, commands: [
        .gearSelected, .acChargerStatus, .dcChargerStatus
      ])
      
    case .tripStarting:
      return ObdCommandPacket(type: .tripStarting, commands: [
        .odometer, .energyToEmpty, .stateOfCharge,
        .stateOfHealth, .batteryTemperature,
        .position, .weather
      ])
    case .tripInProgress:
      return ObdCommandPacket(type: .tripInProgress, commands: [
        .gearSelected
      ])
    case .tripUpdate:
      return ObdCommandPacket(type: .tripUpdate, commands: [
        .position,
        .odometer, .energyToEmpty, .stateOfCharge,
        .batteryTemperature
      ])
    case .tripEnding:
      return ObdCommandPacket(type: .tripEnding, commands: [
        .weather,
        .odometer, .energyToEmpty, .stateOfCharge,
        .stateOfHealth, .batteryTemperature,
        .position
      ])
    case .tripData:
      return ObdCommandPacket(type: .tripData, commands: [
        .odometer, .stateOfCharge, .energyToEmpty, .batteryTemperature
      ])
    case .tripWeather:
      return ObdCommandPacket(type: .tripWeather, commands: [
        .weather
      ])

    case .acChargeStarting:
      return ObdCommandPacket(type: .acChargeStarting, commands: [
        .odometer, .energyToEmpty, .stateOfCharge,
        .stateOfHealth, .batteryTemperature, .acChargerCouplerTemperature,
        .position, .weather
      ])
    case .acChargeInProgress:
      return ObdCommandPacket(type: .acChargeInProgress, commands: [
        .acChargerStatus
      ])
    case .acChargeUpdate:
      return ObdCommandPacket(type: .acChargeUpdate, commands: [
        .stateOfCharge, .energyToEmpty,
        .batteryTemperature, .acChargerCouplerTemperature
      ])
    case .acChargeEnding:
      return ObdCommandPacket(type: .acChargeEnding, commands: [
        .energyToEmpty, .stateOfCharge,
        .stateOfHealth, .batteryTemperature, .acChargerCouplerTemperature
      ])

    case .dcChargeStarting:
      return ObdCommandPacket(type: .dcChargeStarting, commands: [
        .odometer, .energyToEmpty, .stateOfCharge,
        .stateOfHealth, .batteryTemperature, .dcChargerCouplerTemperature,
        .position, .weather
      ])
    case .dcChargeInProgress:
      return ObdCommandPacket(type: .dcChargeInProgress, commands: [
        .dcChargerStatus
      ])
    case .dcChargeUpdate:
      return ObdCommandPacket(type: .dcChargeUpdate, commands: [
        .stateOfCharge, .energyToEmpty,
        .batteryTemperature, .dcChargerCouplerTemperature
      ])
    case .dcChargeEnding:
      return ObdCommandPacket(type: .dcChargeEnding, commands: [
        .energyToEmpty, .stateOfCharge,
        .stateOfHealth, .batteryTemperature, .dcChargerCouplerTemperature
      ])

    case .acChargeHistory:
      return ObdCommandPacket(
        type: .acChargeHistory,
        commands: [
        .energyToEmpty, .stateOfCharge,
        .batteryTemperature, .acChargerCouplerTemperature
      ])
    case .dcChargeHistory:
      return ObdCommandPacket(
        type: .dcChargeHistory,
        commands: [
        .energyToEmpty, .stateOfCharge,
        .batteryTemperature, .dcChargerCouplerTemperature
      ])

    case .tripEnergy:
      return ObdCommandPacket(type: .tripEnergy, commands: [
        .batteryVoltage, .batteryCurrent
      ])
    case .acChargeEnergy:
      return ObdCommandPacket(type: .acChargeEnergy, commands: [
        .batteryVoltage, .batteryCurrent
      ])
    case .dcChargeEnergy:
      return ObdCommandPacket(type: .dcChargeEnergy, commands: [
        .batteryVoltage, .batteryCurrent
      ])

    default:
      DokoLogging.shared.postLoggingResponse(.error("FE.translateDokoCommandPacket: no packet translation for '\(packetType.description)'"))
      return nil
    }
  }
}
