import OSLog

import DokoTypes
import DokoLogging
import VehicleInterface
import ObdLinkCore
import Vehicles

public actor VwElectrics: ConnectedVehicleInterface {
  let logger = Logger(subsystem: "com.unchan.doko", category: "VwElectrics")

  nonisolated public let vehicle: Vehicle?
  nonisolated public let name: String = "VwElectrics"

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
    let obdLinkCommand: String?
    switch command {
    case .stpx(let header, let did):    obdLinkCommand = String(format: "STPX h:%X, d:22%0X", header, did)
    case .ath(let enabled):             obdLinkCommand = "ATH\(enabled ? 1 : 0)"

    case .gearSelected:                 obdLinkCommand = "STPX h:17FC0076, d:22210E"    //0x17fc0076 03 22 21 0e 55 55 55 55
    case .odometer:                     obdLinkCommand = "STPX h:17FC0076, d:22295A"    //0x17fe0076 06 62 29 5a XX YY ZZ aa  (XX*2^16+YY*2^8+ZZ) = km in decimal

    case .stateOfCharge:                obdLinkCommand = "STPX h:17FC007B, d:22028C"    //0x17fc007b 03 22 02 8c 55 55 55 55
    case .batteryTemperature:           obdLinkCommand = "STPX h:17FC007B, d:222A0B"    //0x17fc007b 03 22 2a 0b
    case .batteryVoltage:               obdLinkCommand = "STPX h:17FC007B, d:221E3B"    //0x17fc007b 03 22 1e 3b 55 55 55 55
    case .batteryCurrent:               obdLinkCommand = "STPX h:17FC007B, d:221E3D"    //0x17fc007b 03 22 1e 3d 55 55 55 55

    case .acChargerStatus:              obdLinkCommand = "STPX h:17FC007B, d:227448"    //0x17fc007b 03 22 74 48 55 55 55 55
    case .dcChargerStatus:              obdLinkCommand = "STPX h:17FC007B, d:227448"    //0x17fc007b 03 22 74 48 55 55 55 55

    case .position:                     obdLinkCommand = ""
    case .weather:                      obdLinkCommand = ""

    default:                            obdLinkCommand = nil
    }
    guard let obdLinkCommand else {
      DokoLogging.shared.postLoggingResponse(.error("FE.vehicleObdCommand: \(command.description) not found"))
      return nil
    }
    return obdLinkCommand
  }

  public func translateDokoCommandPacket(using packetType: DokoPacketType) async -> ObdCommandPacket? {
    switch packetType {
    case .vehicleCustomization:
      return ObdCommandPacket(type: .vehicleCustomization, commands: [
        //### custom reinitialization
        .ath(true),
        .stpx(0x18DB33F1, 0xF190),
        .stpx(0x18DB33F1, 0xF18C),
        .ath(false),

        .gearSelected, .odometer,
        .acChargerStatus, .dcChargerStatus,
        .stateOfCharge, .batteryTemperature, .batteryVoltage, .batteryCurrent
      ])

    case .idle:
      return ObdCommandPacket(type: .idle, commands: [
        .gearSelected,
        .acChargerStatus, .dcChargerStatus
      ])

    case .tripStarting:
      return ObdCommandPacket(type: .tripStarting, commands: [
        .odometer,
        .stateOfCharge,
        .batteryTemperature,
        .position, .weather,
      ])
    case .tripInProgress:
      return ObdCommandPacket(type: .tripInProgress, commands: [
        .gearSelected,
      ])
    case .tripUpdate:
      return ObdCommandPacket(type: .tripUpdate, commands: [
        .odometer,
        .stateOfCharge,
        .batteryTemperature,
        .position,
      ])
    case .tripEnding:
      return ObdCommandPacket(type: .tripEnding, commands: [
        .weather,
        .odometer,
        .stateOfCharge,
        .batteryTemperature,
        .position,
      ])
    case .tripData:
      return ObdCommandPacket(type: .tripData, commands: [
        .odometer,
        .stateOfCharge, .batteryTemperature
      ])
    case .tripWeather:
      return ObdCommandPacket(type: .tripWeather, commands: [
        .weather
      ])

    case .acChargeStarting:
      return ObdCommandPacket(type: .acChargeStarting, commands: [
        .odometer, .stateOfCharge,
        .batteryTemperature,
        .position, .weather,
      ])
    case .acChargeInProgress:
      return ObdCommandPacket(type: .acChargeInProgress, commands: [
        .acChargerStatus
      ])
    case .acChargeUpdate:
      return ObdCommandPacket(type: .acChargeUpdate, commands: [
        .stateOfCharge,
        .batteryTemperature,
      ])
    case .acChargeEnding:
      return ObdCommandPacket(type: .acChargeEnding, commands: [
        .stateOfCharge,
        .batteryTemperature,
      ])

    case .dcChargeStarting:
      return ObdCommandPacket(type: .dcChargeStarting, commands: [
        .odometer,  .stateOfCharge,
        .batteryTemperature,
        .position, .weather,
      ])
    case .dcChargeInProgress:
      return ObdCommandPacket(type: .dcChargeInProgress, commands: [
        .dcChargerStatus
      ])
    case .dcChargeUpdate:
      return ObdCommandPacket(type: .dcChargeUpdate, commands: [
        .stateOfCharge,
        .batteryTemperature,
      ])
    case .dcChargeEnding:
      return ObdCommandPacket(type: .dcChargeEnding, commands: [
        .stateOfCharge,
        .batteryTemperature,
      ])

    case .acChargeHistory:
      return ObdCommandPacket(
        type: .acChargeHistory,
        commands: [
        .stateOfCharge,
        .batteryTemperature,
      ])
    case .dcChargeHistory:
      return ObdCommandPacket(
        type: .dcChargeHistory,
        commands: [
        .stateOfCharge,
        .batteryTemperature,
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
      DokoLogging.shared.postLoggingResponse(.error("VWE.translateDokoCommandPacket: no packet translation for '\(packetType.description)'"))
      return nil
    }
  }
}
