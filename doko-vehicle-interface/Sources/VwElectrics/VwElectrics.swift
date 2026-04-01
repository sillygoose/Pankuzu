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
    case .atz:                          obdLinkCommand = "ATZ"
    case .ate(let enabled):             obdLinkCommand = "ATE \(enabled ? 1 : 0)"
    case .ath(let enabled):             obdLinkCommand = "ATH \(enabled ? 1 : 0)"
    case .atcaf(let enabled):           obdLinkCommand = "ATCAF \(enabled ? 1 : 0)"
    case .ats(let enabled):             obdLinkCommand = "ATS \(enabled ? 1 : 0)"
    case .atsp(let canProtocol):        obdLinkCommand = "ATSP \(canProtocol)"
    case .atsh(let header):             obdLinkCommand = "ATSH \(header)"
    case .atcp(let header):             obdLinkCommand = "ATCP \(header)"
    case .atcf(let pattern):            obdLinkCommand = "ATCF \(pattern)"
    case .atcra(let pattern):           obdLinkCommand = "ATCRA \(pattern)" //obdLinkCommand = String(format: "ATCRA %X", pattern) //"ATCRA\(pattern)"
    case .atcm(let mask):               obdLinkCommand = "ATCM \(mask)" // "ATCM\(mask)"
    case .stcsegr(let enabled):         obdLinkCommand = "STCSEGR \(enabled ? 1 : 0)"

    case .batteryVoltage0:              obdLinkCommand = "STPX h:17FC007B, d:221E3B"
    case .batteryVoltage1:              obdLinkCommand = "STPX h:17FC007B, d:221E3D"
    case .batteryVoltage2:              obdLinkCommand = "STPX h:17FC007B, d:227448"
    case .batteryVoltage3:              obdLinkCommand = "STPX h:17FC007B, d:22028C"
    case .batteryVoltage4:              obdLinkCommand = "STPX h:17FC007B, d:222A0B"

    case .batteryCurrent0:              obdLinkCommand = "STPX h:17FC0076, d:22295A"
    case .batteryCurrent1:              obdLinkCommand = "STPX h:17FC0076, d:22210E"

//    case .batteryVoltage1:              obdLinkCommand = "221E3B"
//    case .batteryCurrent1:              obdLinkCommand = "221E3D"

//    case .batteryVoltage2:              obdLinkCommand = "03221E3B"
//    case .batteryCurrent2:              obdLinkCommand = "03221E3D"
//    case .batteryVoltage3:              obdLinkCommand = "03221E3B"
//    case .batteryCurrent3:              obdLinkCommand = "03221E3D"
//
//    case .batteryVoltage4:              obdLinkCommand = "221E3B"
//    case .batteryCurrent4:              obdLinkCommand = "221E3D"
//    case .batteryVoltage5:              obdLinkCommand = "221E3B"
//    case .batteryCurrent5:              obdLinkCommand = "221E3D"
//    case .batteryVoltage6:              obdLinkCommand = "221E3B"
//    case .batteryCurrent6:              obdLinkCommand = "221E3D"
//    case .batteryVoltage7:              obdLinkCommand = "221E3B"
//    case .batteryCurrent7:              obdLinkCommand = "221E3D"

    case .gearSelected:                 obdLinkCommand = "22210E" //"STPX h:17FC0076, d:22210E"    //0x17fc0076 03 22 21 0e 55 55 55 55
    case .odometer:                     obdLinkCommand = "22295A" //"STPX h:17FC0076, d:22295A"    //0x17fe0076 06 62 29 5a XX YY ZZ aa  (XX*2^16+YY*2^8+ZZ) = km in decimal

    case .batteryVoltage:               obdLinkCommand = "221E3B" //"03221E3B55555555" //STPX h:17FC007B, d:221E3B"    //0x17fc007b 03 22 1e 3b 55 55 55 55
    case .batteryCurrent:               obdLinkCommand = "221E3D" //"03221E3D55555555" //STPX h:17FC007B, d:221E3D"    //0x17fc007b 03 22 1e 3d 55 55 55 55
    case .stateOfCharge:                obdLinkCommand = "22028C" //STPX h:17FC007B, d:22028C"    //0x17fc007b 03 22 02 8c 55 55 55 55
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
        //.atcp("17"),
        //.atsh("FC007B"),
        .atcra("17FE007X"),
        
        .batteryVoltage0,
        .batteryVoltage1,
        .batteryVoltage2,
        .batteryVoltage3,
        .batteryVoltage4,

        .batteryCurrent0,
        .batteryCurrent1,

//        .atcp(""),
//        .atsh(""),

        .atz,
        .ate(false),
        .atsp(7),
        .ath(true),
        .ats(false),
        .atcaf(false),
        .atcp("17"),
        //
        .atsh("FC007B"),
//        .batteryVoltage2, .batteryCurrent2,
        //
        .atcra("17FE007X"),
//        .batteryVoltage3, .batteryCurrent3,
        //
        .atcaf(true),
//        .batteryVoltage4, .batteryCurrent4,
        //
        .ath(false),
//        .batteryVoltage5, .batteryCurrent5,
        //
        .stcsegr(true),
//        .batteryVoltage6, .batteryCurrent6,
        //
        .atsh("FC007B"),
        .acChargerStatus, .dcChargerStatus,
        .stateOfCharge,
        .batteryTemperature,
        //
        .atsh("FC0076"),
        .gearSelected, .odometer,
      ])

    case .idle:
      return ObdCommandPacket(type: .idle, commands: [
        .atsh("FC007B"),
        .acChargerStatus, .dcChargerStatus,

        .atsh("FC0076"),
        .gearSelected,
//        .gearSelected,
//        .acChargerStatus, .dcChargerStatus
      ])

    case .tripStarting:
      return ObdCommandPacket(type: .tripStarting, commands: [
        .atsh("FC0076"),
        .odometer,

          .atsh("FC007B"),
        .stateOfCharge,
        .batteryTemperature,

        .position, .weather,
      ])
    case .tripInProgress:
      return ObdCommandPacket(type: .tripInProgress, commands: [
        .atsh("FC0076"),
        .gearSelected,
      ])
    case .tripUpdate:
      return ObdCommandPacket(type: .tripUpdate, commands: [
        .position,

        .atsh("FC0076"),
        .odometer,

        .atsh("FC007B"),
        .stateOfCharge, //###.stateOfHealth,
        .batteryTemperature,
      ])
    case .tripEnding:
      return ObdCommandPacket(type: .tripEnding, commands: [
        .weather,

        .atsh("FC0076"),
        .odometer,

        .atsh("FC007B"),
        .stateOfCharge,
        .batteryTemperature,

        .position,
      ])
    case .tripData:
      return ObdCommandPacket(type: .tripData, commands: [
        .atsh("FC0076"),
        .odometer,

        .atsh("FC007B"),
        .stateOfCharge, .batteryTemperature
      ])
    case .tripWeather:
      return ObdCommandPacket(type: .tripWeather, commands: [
        .weather
      ])

    case .acChargeStarting:
      return ObdCommandPacket(type: .acChargeStarting, commands: [
        .atsh("FC0076"),
        .odometer,

        .atsh("FC007B"),
        .stateOfCharge,
        .batteryTemperature,

        .position, .weather,
      ])
    case .acChargeInProgress:
      return ObdCommandPacket(type: .acChargeInProgress, commands: [
        .atsh("FC007B"),
        .acChargerStatus
      ])
    case .acChargeUpdate:
      return ObdCommandPacket(type: .acChargeUpdate, commands: [
        .atsh("FC0076"),
        .odometer,

        .atsh("FC007B"),
        .stateOfCharge, //###.stateOfHealth,
        .batteryTemperature,
      ])
    case .acChargeEnding:
      return ObdCommandPacket(type: .acChargeEnding, commands: [
        .atsh("FC007B"),
        .stateOfCharge,
        .batteryTemperature,
      ])

    case .dcChargeStarting:
      return ObdCommandPacket(type: .dcChargeStarting, commands: [
        .atsh("FC0076"),
        .odometer,

        .atsh("FC007B"),
        .stateOfCharge,
        .batteryTemperature,
        .position, .weather,
      ])
    case .dcChargeInProgress:
      return ObdCommandPacket(type: .dcChargeInProgress, commands: [
        .atsh("FC007B"),
        .dcChargerStatus
      ])
    case .dcChargeUpdate:
      return ObdCommandPacket(type: .dcChargeUpdate, commands: [
        .atsh("FC0076"),
        .odometer,

        .atsh("FC007B"),
        .stateOfCharge, //###.stateOfHealth,
        .batteryTemperature,
      ])
    case .dcChargeEnding:
      return ObdCommandPacket(type: .dcChargeEnding, commands: [
        .atsh("FC007B"),
        .stateOfCharge,
        .batteryTemperature,
      ])

    case .acChargeHistory:
      return ObdCommandPacket(type: .acChargeHistory, commands: [
        .atsh("FC007B"),
        .stateOfCharge,
        .batteryTemperature,
      ])
    case .dcChargeHistory:
      return ObdCommandPacket(type: .dcChargeHistory, commands: [
        .atsh("FC007B"),
        .stateOfCharge,
        .batteryTemperature,
      ])

    case .tripEnergy:
      return ObdCommandPacket(type: .tripEnergy, commands: [
        .atsh("FC007B"),
        .batteryVoltage, .batteryCurrent
      ])
    case .acChargeEnergy:
      return ObdCommandPacket(type: .acChargeEnergy, commands: [
        .atsh("FC007B"),
        .batteryVoltage, .batteryCurrent
      ])
    case .dcChargeEnergy:
      return ObdCommandPacket(type: .dcChargeEnergy, commands: [
        .atsh("FC007B"),
        .batteryVoltage, .batteryCurrent
      ])

    default:
      DokoLogging.shared.postLoggingResponse(.error("VWE.translateDokoCommandPacket: no packet translation for '\(packetType.description)'"))
      return nil
    }
  }
}
