import OSLog

import DokoTypes
import DokoLogging
import VehicleInterface
import ObdLinkCore
import Vehicles

public actor FordMachE: ConnectedVehicleInterface {
  let logger = Logger(subsystem: "com.unchan.doko", category: "FordMachE")

  nonisolated public let vehicle: Vehicle?
  nonisolated public let name: String = "FordMachE"

  public var batteryPower: Double?
  public var batteryEnergy: Double?
  public var lastEnergyUpdateTime: Date?
  public var lastBatteryPower: Double?

  public var meanTemperatureSum: Double = 0.0
  public var meanTemperatureCount: Int = 0

  public init(vehicle: Vehicle?) {
    self.vehicle = vehicle
  }

  public func vehicleObdCommand(_ command: ObdCommand) async -> String? {
    let obdLinkCommand: String?
    switch command {
    case .stpx(let header, let did):    obdLinkCommand = String(format: "STPX h:%X, d:22%0X", header, did)
    case .ath(let enabled):             obdLinkCommand = "ATH\(enabled ? 1 : 0)"

    case .stpo:                         obdLinkCommand = "STPO"
    case .stp(let canProtocol):         obdLinkCommand = "STP\(canProtocol)"
    case .stpbr(let baudRate):          obdLinkCommand = "STPBR\(baudRate)"

    case .gearSelected:                 obdLinkCommand = "STPX h:7E2, d:221E12"
    case .acChargerCouplerTemperature:  obdLinkCommand = "STPX h:7E2, d:224888"
    case .dcChargerCouplerTemperature:  obdLinkCommand = "STPX h:7E2, d:224897"

    case .energyToEmpty:                obdLinkCommand = "STPX h:7E4, d:224848"
    case .stateOfCharge:                obdLinkCommand = "STPX h:7E4, d:224845"
    case .stateOfHealth:                obdLinkCommand = "STPX h:7E4, d:22490C"
    case .batteryTemperature:           obdLinkCommand = "STPX h:7E4, d:224800"
      
    case .batteryVoltage:               obdLinkCommand = "STPX h:7E4, d:22480D"
    case .batteryCurrent:               obdLinkCommand = "STPX h:7E4, d:2248F9"

    case .acChargerStatus:              obdLinkCommand = "STPX h:7E4, d:22484F"
    case .dcChargerStatus:              obdLinkCommand = "STPX h:7E4, d:22489E"

    case .odometer:                     obdLinkCommand = "STPX h:720, d:22404C"
    case .speed:                        obdLinkCommand = "STPX h:7DF, d:221505"

    case .position:                     obdLinkCommand = ""
    case .weather:                      obdLinkCommand = ""
      
    default:                            obdLinkCommand = nil
    }
    guard let obdLinkCommand else {
      DokoLogging.shared.postLoggingResponse(.error("FME.vehicleObdCommand: \(command.description) not found"))
      return nil
    }
    return obdLinkCommand
  }
 
  public func translateDokoCommandPacket(using packetType: DokoPacketType) async -> ObdCommandPacket? {
    switch packetType {
    case .vehicleCustomization:
      return ObdCommandPacket(type: .vehicleCustomization, commands: [
        .stp(53), .stpbr(500000), .stpo,
        .speed, .speed
      ])

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
        .position, .odometer,
        .stateOfCharge, .stateOfHealth,
        .batteryTemperature,
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
        .odometer,
        .stateOfCharge, .stateOfHealth,
        .batteryTemperature,
        .acChargerCouplerTemperature
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
        .odometer,
        .stateOfCharge, .stateOfHealth,
        .batteryTemperature,
        .acChargerCouplerTemperature
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
      DokoLogging.shared.postLoggingResponse(.error("FME.translateDokoCommandPacket: no packet translation for '\(packetType.description)'"))
      return nil
    }
  }
}
