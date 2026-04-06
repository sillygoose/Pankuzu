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
    case .atcra(let pattern):           obdLinkCommand = "ATCRA \(pattern)"
    case .atcm(let mask):               obdLinkCommand = "ATCM \(mask)"
    case .stcsegr(let enabled):         obdLinkCommand = "STCSEGR \(enabled ? 1 : 0)"

    case .batteryCurrent0:              obdLinkCommand = "STPX h:17FC007B, d:221E3D"
    case .batteryCurrent1:              obdLinkCommand = "STPX h:17FC007B, d:221E3D"
    case .batteryCurrent2:              obdLinkCommand = "STPX h:17FC007B, d:221E3D"
    case .batteryCurrent3:              obdLinkCommand = "STPX h:17FC007B, d:221E3D"

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

    case .gearSelected:                 obdLinkCommand = "STPX h:17FC0076, d:22210E"
    case .odometer:                     obdLinkCommand = "STPX h:17FC0076, d:22295A"
    case .speed:                        obdLinkCommand = "010D"

    case .batteryVoltage:               obdLinkCommand = "STPX h:17FC007B, d:221E3B"
    case .batteryCurrent:               obdLinkCommand = "STPX h:17FC007B, d:221E3D"
    case .batteryStateOfCharge:         obdLinkCommand = "STPX h:17FC007B, d:22028C"
    case .batteryStateOfHealth:         obdLinkCommand = "STPX h:17FC007B, d:222AB2"
    case .batteryTemperature:           obdLinkCommand = "STPX h:17FC007B, d:222A0B"
    case .batteryDistanceToEmpty:       obdLinkCommand = "STPX h:17FC007B, d:222AB6"

    case .acChargerStatus:              obdLinkCommand = "STPX h:17FC007B, d:227448"
    case .dcChargerStatus:              obdLinkCommand = "STPX h:17FC007B, d:227448"

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
        //.atz, .ate(false), .ats(false), .ath(false), .atcaf(true), .stcsegr(true), .atsp(0)
        .atcra("17FE007X"),

        .ath(true),

        .atcaf(false),
        .stcsegr(false),
        .batteryCurrent0,
        .atcaf(true),
        .stcsegr(false),
        .batteryCurrent1,
        .atcaf(false),
        .stcsegr(true),
        .batteryCurrent2,
        .atcaf(true),
        .stcsegr(true),
        .batteryCurrent3,
        
        .stcsegr(true),
        .atcaf(true),
        .ath(false),
        
        //        .speed,
//
//        .batteryCurrent0,
        
//        .batteryCurrent1,

//        .atcp(""),
//        .atsh(""),

////        .batteryVoltage2, .batteryCurrent2,
//        //
//        .atcra("17FE007X"),
////        .batteryVoltage3, .batteryCurrent3,
//        //
//        .atcaf(true),
////        .batteryVoltage4, .batteryCurrent4,
//        //
//        .ath(false),
////        .batteryVoltage5, .batteryCurrent5,
//        //
//        .stcsegr(true),
////        .batteryVoltage6, .batteryCurrent6,
//        //
        .acChargerStatus, .dcChargerStatus,
        .gearSelected, .odometer,
        .batteryStateOfCharge, .batteryStateOfHealth, .batteryTemperature,
        .batteryVoltage, //.batteryCurrent,
        .batteryDistanceToEmpty,
      ])

    case .idle:
      return ObdCommandPacket(type: .idle, commands: [
        .acChargerStatus, .dcChargerStatus,
        .gearSelected,
      ])

    case .tripStarting:
      return ObdCommandPacket(type: .tripStarting, commands: [
        .odometer,
        .batteryStateOfCharge, .batteryStateOfHealth, .batteryTemperature,
        .batteryDistanceToEmpty,
        .position, .weather,
      ])
    case .tripInProgress:
      return ObdCommandPacket(type: .tripInProgress, commands: [
        .gearSelected,
      ])
    case .tripUpdate:
      return ObdCommandPacket(type: .tripUpdate, commands: [
        .position,
        .odometer,
        .batteryStateOfCharge, .batteryTemperature,
        .batteryDistanceToEmpty,
      ])
    case .tripEnding:
      return ObdCommandPacket(type: .tripEnding, commands: [
        .weather,
        .odometer,
        .batteryStateOfCharge, .batteryStateOfHealth, .batteryTemperature,
        .batteryDistanceToEmpty,
        .position,
      ])
    case .tripData:
      return ObdCommandPacket(type: .tripData, commands: [
        .odometer,
        .batteryStateOfCharge, .batteryTemperature
      ])
    case .tripWeather:
      return ObdCommandPacket(type: .tripWeather, commands: [
        .weather
      ])

    case .acChargeStarting:
      return ObdCommandPacket(type: .acChargeStarting, commands: [
        .odometer,
        .batteryStateOfCharge, .batteryStateOfHealth, .batteryTemperature,
        .batteryDistanceToEmpty,
        .position, .weather,
      ])
    case .acChargeInProgress:
      return ObdCommandPacket(type: .acChargeInProgress, commands: [
        .acChargerStatus
      ])
    case .acChargeUpdate:
      return ObdCommandPacket(type: .acChargeUpdate, commands: [
        .odometer,
        .batteryStateOfCharge, .batteryTemperature,
      ])
    case .acChargeEnding:
      return ObdCommandPacket(type: .acChargeEnding, commands: [
        .batteryStateOfCharge, .batteryTemperature,
        .batteryDistanceToEmpty,
      ])

    case .dcChargeStarting:
      return ObdCommandPacket(type: .dcChargeStarting, commands: [
        .odometer,
        .batteryStateOfCharge, .batteryStateOfHealth, .batteryTemperature,
        .batteryDistanceToEmpty,
        .position, .weather,
      ])
    case .dcChargeInProgress:
      return ObdCommandPacket(type: .dcChargeInProgress, commands: [
        .dcChargerStatus
      ])
    case .dcChargeUpdate:
      return ObdCommandPacket(type: .dcChargeUpdate, commands: [
        .odometer,
        .batteryStateOfCharge, .batteryTemperature,
      ])
    case .dcChargeEnding:
      return ObdCommandPacket(type: .dcChargeEnding, commands: [
        .batteryStateOfCharge, .batteryTemperature,
        .batteryDistanceToEmpty,
      ])

    case .acChargeHistory:
      return ObdCommandPacket(type: .acChargeHistory, commands: [
        .batteryStateOfCharge, .batteryTemperature,
      ])
    case .dcChargeHistory:
      return ObdCommandPacket(type: .dcChargeHistory, commands: [
        .batteryStateOfCharge, .batteryTemperature,
      ])

//    case .tripEnergy:
//      return ObdCommandPacket(type: .tripEnergy, commands: [
//        .batteryVoltage, .batteryCurrent
//      ])
//    case .acChargeEnergy:
//      return ObdCommandPacket(type: .acChargeEnergy, commands: [
//        .batteryVoltage, .batteryCurrent
//      ])
//    case .dcChargeEnergy:
//      return ObdCommandPacket(type: .dcChargeEnergy, commands: [
//        .batteryVoltage, .batteryCurrent
//      ])

    default:
//      DokoLogging.shared.postLoggingResponse(.error("VWE.translateDokoCommandPacket: no packet translation for '\(packetType.description)'"))
      return nil
    }
  }
}
