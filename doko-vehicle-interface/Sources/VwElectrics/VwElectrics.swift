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
    case .atz:                          obdLinkCommand = "ATZ"
    case .ate(let enabled):             obdLinkCommand = "ATE \(enabled ? 1 : 0)"
    case .ath(let enabled):             obdLinkCommand = "ATH \(enabled ? 1 : 0)"
    case .atcaf(let enabled):           obdLinkCommand = "ATCAF \(enabled ? 1 : 0)"
    case .ats(let enabled):             obdLinkCommand = "ATS \(enabled ? 1 : 0)"
    case .atsp(let canProtocol):        obdLinkCommand = "ATSP \(canProtocol)"
    case .atsh(let header):             obdLinkCommand = String(format: "ATSH %X", header)
    case .atcp(let header):             obdLinkCommand = String(format: "ATCP %X", header)
    case .atcf(let pattern):            obdLinkCommand = String(format: "ATCF %X", pattern)
    case .atcra(let pattern):           obdLinkCommand = "ATCRA \(pattern)" //obdLinkCommand = String(format: "ATCRA %X", pattern) //"ATCRA\(pattern)"
    case .atcm(let mask):               obdLinkCommand = String(format: "ATCM %X", mask) // "ATCM\(mask)"
    case .stcsegr(let enabled):         obdLinkCommand = "STCSEGR \(enabled ? 1 : 0)"
      
    case .gearSelected:                 obdLinkCommand = "22210E" //"STPX h:17FC0076, d:22210E"    //0x17fc0076 03 22 21 0e 55 55 55 55
    case .odometer:                     obdLinkCommand = "22295A" //"STPX h:17FC0076, d:22295A"    //0x17fe0076 06 62 29 5a XX YY ZZ aa  (XX*2^16+YY*2^8+ZZ) = km in decimal

    case .stateOfCharge:                obdLinkCommand = "22028C" //STPX h:17FC007B, d:22028C"    //0x17fc007b 03 22 02 8c 55 55 55 55
    case .batteryVoltage:               obdLinkCommand = "03221E3B" //"03221E3B55555555" //STPX h:17FC007B, d:221E3B"    //0x17fc007b 03 22 1e 3b 55 55 55 55
    case .batteryCurrent:               obdLinkCommand = "03221E3D" //"03221E3D55555555" //STPX h:17FC007B, d:221E3D"    //0x17fc007b 03 22 1e 3d 55 55 55 55
    case .batteryTemperature:           obdLinkCommand = "222A0B" //"STPX h:17FC007B, d:222A0B"    //0x17fc007b 03 22 2a 0b

    case .acChargerStatus:              obdLinkCommand = "227448" //"STPX h:17FC007B, d:227448"    //0x17fc007b 03 22 74 48 55 55 55 55
    case .dcChargerStatus:              obdLinkCommand = "227448" //"STPX h:17FC007B, d:227448"    //0x17fc007b 03 22 74 48 55 55 55 55

    case .position:                     obdLinkCommand = ""
    case .weather:                      obdLinkCommand = ""

    default:                            obdLinkCommand = nil
    }
    guard let obdLinkCommand else {
      DokoLogging.shared.postLoggingResponse(.error("VWE.vehicleObdCommand: \(command.description) not found"))
      return nil
    }
    return obdLinkCommand
  }

  public func translateDokoCommandPacket(using packetType: DokoPacketType) async -> ObdCommandPacket? {
    switch packetType {
    case .vehicleCustomization:
      return ObdCommandPacket(type: .vehicleCustomization, commands: [
        .atz, .ate(false), .atsp(7),
        .atcaf(false),
        .atcp(0x17), // .atcf(0x17FE7),
        .atcra("17FE007X"),

        .atsh(0xFC007B),
        .acChargerStatus, .dcChargerStatus,
        .stateOfCharge, .batteryVoltage, .batteryCurrent, .batteryTemperature,
        
        .atsh(0xFC0076),
        .gearSelected, .odometer,
        
        .atcaf(true),
        .stcsegr(true),
      ])

    case .idle:
      return ObdCommandPacket(type: .idle, commands: [
        .atsh(0xFC007B),
        .acChargerStatus, .dcChargerStatus,
        .stateOfCharge, .batteryVoltage, .batteryCurrent, .batteryTemperature,
        
        .atsh(0xFC0076),
        .gearSelected, .odometer,

//        .gearSelected,
//        .acChargerStatus, .dcChargerStatus
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
