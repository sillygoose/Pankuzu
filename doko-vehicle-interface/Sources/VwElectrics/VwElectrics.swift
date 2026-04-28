import OSLog

import DokoTypes
import DokoLogging
import VehicleInterface
import ObdLinkCore
import Vehicles

private struct CommandGroup {
  let commands: [ObdCommand]
}

private let can11Bit = CommandGroup(commands: [.stp(33), .stpo, .atcra("77A"), .atfcsh("710")])
private let can29Bit = CommandGroup(commands: [.stp(34), .stpo, .atfcsh("17FC007B"), .atcra("17FE007X")])

@resultBuilder
private enum ObdCommandsBuilder {
  static func buildExpression(_ e: ObdCommand) -> [ObdCommand] { [e] }
  static func buildExpression(_ e: CommandGroup) -> [ObdCommand] { e.commands }
  static func buildBlock(_ components: [ObdCommand]...) -> [ObdCommand] { components.flatMap { $0 } }
}

private func obdPacket(_ type: DokoPacketType, @ObdCommandsBuilder _ commands: () -> [ObdCommand]) -> ObdCommandPacket {
  ObdCommandPacket(type: type, commands: commands())
}

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

  public init(
    vehicle: Vehicle?
  ) {
    self.vehicle = vehicle
  }

  public func vehicleObdCommand(_ command: ObdCommand) async -> String? {
    let obdLinkCommand: String?
    switch command {
    case .atz:                          obdLinkCommand = "ATZ"
    case .ate(let enabled):             obdLinkCommand = "ATE \(enabled ? 1 : 0)"
    case .ath(let enabled):             obdLinkCommand = "ATH \(enabled ? 1 : 0)"
    case .atcfc(let enabled):           obdLinkCommand = "ATCFC \(enabled ? 1 : 0)"
    case .atfcsm(let mode):             obdLinkCommand = "ATFCSM \(mode)"
    case .atfcsh(let header):           obdLinkCommand = "ATFCSH \(header)"
    case .atfcsd(let data):             obdLinkCommand = "ATFCSD \(data)"
    case .atcaf(let enabled):           obdLinkCommand = "ATCAF \(enabled ? 1 : 0)"
    case .ats(let enabled):             obdLinkCommand = "ATS \(enabled ? 1 : 0)"
    case .atsp(let canProtocol):        obdLinkCommand = "ATSP \(canProtocol)"
    case .atsh(let header):             obdLinkCommand = "ATSH \(header)"
    case .atcp(let header):             obdLinkCommand = "ATCP \(header)"
    case .atcf(let pattern):            obdLinkCommand = "ATCF \(pattern)"
    case .atcra(let pattern):           obdLinkCommand = "ATCRA \(pattern)"
    case .atcm(let mask):               obdLinkCommand = "ATCM \(mask)"
    case .stcsegr(let enabled):         obdLinkCommand = "STCSEGR \(enabled ? 1 : 0)"
    case .stpo:                         obdLinkCommand = "STPO"
    case .stp(let canProtocol):         obdLinkCommand = "STP \(canProtocol)"
    case .stpbr(let baudRate):          obdLinkCommand = "STPBR \(baudRate)"

    case .gearSelected:                 obdLinkCommand = "STPX h:17FC0076, d:22210E"
    case .odometer:                     obdLinkCommand = "STPX h:17FC0076, d:22295A"
    case .speed:                        obdLinkCommand = "STPX h:17FC007B, d:22F40D"

    case .batteryVoltage:               obdLinkCommand = "STPX h:17FC007B, d:221E3B"
    case .batteryCurrent:               obdLinkCommand = "STPX h:17FC007B, d:221E3D"
    case .batteryStateOfCharge:         obdLinkCommand = "STPX h:17FC007B, d:22028C"
    case .batteryTemperature:           obdLinkCommand = "STPX h:17FC007B, d:222A0B"
    case .batteryOriginalCapacity:      obdLinkCommand = "STPX h:17FC007B, d:22F1B3"

    case .batteryCurrentCapacity:       obdLinkCommand = "STPX h:710, d:222AB2"
    case .batteryDistanceToEmpty:       obdLinkCommand = "STPX h:710, d:222AB5"

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
        .atfcsh("17FC007B"),
        .atfcsd("300000"),
        .atfcsm(1),

        .acChargerStatus, .dcChargerStatus,
        .gearSelected, .odometer, .speed,
        .batteryStateOfCharge, .batteryTemperature,
        .batteryOriginalCapacity,
        .batteryVoltage, .batteryCurrent,

        //.batteryCurrentCapacity, .batteryDistanceToEmpty,
      ])

    case .idle:
      return ObdCommandPacket(type: .idle, commands: [
        .acChargerStatus, .dcChargerStatus,
        .gearSelected,
      ])

    case .tripStarting:
      return obdPacket(.tripStarting) {
        .odometer;
        .batteryStateOfCharge;
        .batteryTemperature;
        can11Bit;
        .batteryDistanceToEmpty;
        can29Bit;
        .position
      }
    case .tripInProgress:
      return ObdCommandPacket(type: .tripInProgress, commands: [
        .gearSelected,
      ])
    case .tripUpdate:
      return ObdCommandPacket(type: .tripUpdate, commands: [
        .position,
        .odometer,
        .batteryStateOfCharge, .batteryTemperature,
        //.batteryDistanceToEmpty,
      ])
    case .tripEnding:
      return obdPacket(.tripEnding) {
        .weather;
        .odometer;
        .batteryStateOfCharge;
        .batteryTemperature;
        .batteryOriginalCapacity;
        can11Bit;
        .batteryCurrentCapacity;
        .batteryDistanceToEmpty;
        can29Bit;
        .position
      }
    case .tripData:
      return ObdCommandPacket(type: .tripData, commands: [
        .odometer,
        .batteryStateOfCharge, .batteryTemperature,
        //.batteryDistanceToEmpty,
      ])
    case .tripWeather:
      return ObdCommandPacket(type: .tripWeather, commands: [
        .weather
      ])

    case .acChargeStarting:
      return ObdCommandPacket(type: .acChargeStarting, commands: [
        .odometer,
        .batteryStateOfCharge,
        .batteryTemperature,
        // 11-but can commands
        //.batteryDistanceToEmpty,
        //.batteryCurrentCapacity,
        // 29-bit can commands
        .position, .weather,
      ])
    case .acChargeInProgress:
      return ObdCommandPacket(type: .acChargeInProgress, commands: [
        .acChargerStatus
      ])
    case .acChargeUpdate:
      return ObdCommandPacket(type: .acChargeUpdate, commands: [
        .batteryStateOfCharge, .batteryTemperature,
      ])
    case .acChargeEnding:
      return ObdCommandPacket(type: .acChargeEnding, commands: [
        .batteryStateOfCharge, .batteryTemperature,
        .batteryOriginalCapacity,
        // 11-but can commands
        //.batteryDistanceToEmpty,
        //.batteryCurrentCapacity,
        // 29-bit can commands
      ])

    case .dcChargeStarting:
      return ObdCommandPacket(type: .dcChargeStarting, commands: [
        .odometer,
        .batteryStateOfCharge,
        .batteryTemperature,
        // 11-but can commands
        //.batteryDistanceToEmpty,
        //.batteryCurrentCapacity,
        // 29-bit can commands
        .position, .weather,
      ])
    case .dcChargeInProgress:
      return ObdCommandPacket(type: .dcChargeInProgress, commands: [
        .dcChargerStatus
      ])
    case .dcChargeUpdate:
      return ObdCommandPacket(type: .dcChargeUpdate, commands: [
        .batteryStateOfCharge, .batteryTemperature,
      ])
    case .dcChargeEnding:
      return ObdCommandPacket(type: .dcChargeEnding, commands: [
        .batteryStateOfCharge, .batteryTemperature,
        .batteryOriginalCapacity,
        // 11-but can commands
        //.batteryDistanceToEmpty,
        //.batteryCurrentCapacity,
        // 29-bit can commands
      ])

    case .acChargeHistory:
      return ObdCommandPacket(type: .acChargeHistory, commands: [
        .batteryStateOfCharge, .batteryTemperature,
      ])
    case .dcChargeHistory:
      return ObdCommandPacket(type: .dcChargeHistory, commands: [
        .batteryStateOfCharge, .batteryTemperature,
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

