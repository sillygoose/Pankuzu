import OSLog

import DokoTypes
import DokoLogging
import VehicleInterface
import ObdLinkCore
import Vehicles
import VehicleCommon

private struct CommandGroup {
  let commands: [ObdCommand]
}

@resultBuilder
private enum ObdCommandsBuilder {
  static func buildExpression(_ e: ObdCommand) -> [ObdCommand] { [e] }
  static func buildExpression(_ e: CommandGroup) -> [ObdCommand] { e.commands }
  static func buildBlock(_ components: [ObdCommand]...) -> [ObdCommand] { components.flatMap { $0 } }
}

private func obdCommandPacket(_ type: DokoPacketType, @ObdCommandsBuilder _ commands: () -> [ObdCommand]) -> ObdCommandPacket {
  ObdCommandPacket(type: type, commands: commands())
}

public actor VwElectrics: ConnectedVehicleInterface {
  let logger = Logger(subsystem: "com.unchan.doko", category: "VwElectrics")

  nonisolated public let vehicle: Vehicle?
  nonisolated public let name: String = "VwElectrics"

  public var responseCache: DokoResponseDictionary = [:]
  public var hvBatteryEnergy = PowerEnergyIntegrator()

  public var vehicleOdometer = TripOdometer()
  public var vehicleDuration = DurationTracker()
  public var vehicleMeanTemperature = MeanTemperature()
  public var vehicleEfficiency = TripEfficiency()

  public init(
    vehicle: Vehicle?
  ) {
    self.vehicle = vehicle
  }

  public func vehicleObdCommand(_ command: ObdCommand) async -> String? {
    let obdLinkCommand: String?
    switch command {
    case .atcra(let pattern):             obdLinkCommand = "ATCRA\(pattern)"
    case .atfcsh(let header):             obdLinkCommand = "ATFCSH\(header)"
    case .atfcsd(let data):               obdLinkCommand = "ATFCSD\(data)"
    case .atfcsm(let mode):               obdLinkCommand = "ATFCSM\(mode)"

    case .stpo:                           obdLinkCommand = "STPO"
    case .stp(let canProtocol):           obdLinkCommand = "STP\(canProtocol)"
    case .stpbr(let baudRate):            obdLinkCommand = "STPBR\(baudRate)"

    case .gearSelected:                   obdLinkCommand = "STPX h:17FC0076, d:22210E"
    case .odometer:                       obdLinkCommand = "STPX h:17FC0076, d:22295A"
    case .speed:                          obdLinkCommand = "STPX h:17FC007B, d:22F40D"

    case .batteryVoltage:                 obdLinkCommand = "STPX h:17FC007B, d:221E3B"
    case .batteryCurrent:                 obdLinkCommand = "STPX h:17FC007B, d:221E3D"
    case .batteryStateOfCharge:           obdLinkCommand = "STPX h:17FC007B, d:22028C"
    case .batteryTemperature:             obdLinkCommand = "STPX h:17FC007B, d:222A0B"
    case .batteryOriginalCapacity:        obdLinkCommand = "STPX h:17FC007B, d:22F1B3"

    case .batteryCurrentCapacity:         obdLinkCommand = "STPX h:710, d:222AB2"
    case .batteryDistanceToEmpty:         obdLinkCommand = "STPX h:710, d:222AB5"

    case .acChargerStatus:                obdLinkCommand = "STPX h:17FC007B, d:227448"
    case .dcChargerStatus:                obdLinkCommand = "STPX h:17FC007B, d:227448"

    case .position:                       obdLinkCommand = ""
    case .weather:                        obdLinkCommand = ""

    default:                              obdLinkCommand = nil
    }
    guard let obdLinkCommand else {
      DokoLogging.shared.postLoggingResponse(.error("VWE.vehicleObdCommand: \(command.description) not found"))
      return nil
    }
    return obdLinkCommand
  }

  private let canbusInitialization = CommandGroup(commands: [.atcra("17FE007X"), .atfcsh("17FC007B"), .atfcsd("300000"), .atfcsm(1)])
  private let canbusNormalAddressing = CommandGroup(commands: [.stp(33), .stpo, .atcra("77A"), .atfcsh("710")])
  private let canbusExtendedAddressing = CommandGroup(commands: [.stp(34), .stpo, .atfcsh("17FC007B"), .atcra("17FE007X")])

  public func translateDokoCommandPacket(using packetType: DokoPacketType) async -> ObdCommandPacket? {
    switch packetType {
    case .vehicleCustomization:
      return obdCommandPacket(.vehicleCustomization) {
        canbusInitialization;
      }

    case .idle:
      return obdCommandPacket(.idle) {
        .gearSelected;
        .acChargerStatus;
        .dcChargerStatus;
      }

    case .tripStarting:
      return obdCommandPacket(.tripStarting) {
        .odometer;
        .batteryStateOfCharge;
        .batteryTemperature;
        canbusNormalAddressing;
        .batteryDistanceToEmpty;
        canbusExtendedAddressing;
        .position;
      }

    case .tripInProgress:
      return obdCommandPacket(.tripInProgress) {
        .gearSelected;
      }

    case .tripUpdate:
      return obdCommandPacket(.tripUpdate) {
        .position;
      }

    case .tripEnding:
      return obdCommandPacket(.tripEnding) {
        .weather;
        .position;
        .odometer;
        .batteryStateOfCharge;
        .batteryTemperature;
        .batteryOriginalCapacity;
        canbusNormalAddressing;
        .batteryCurrentCapacity;
        .batteryDistanceToEmpty;
        canbusExtendedAddressing;
      }

    case .tripOdometer:
      return obdCommandPacket(packetType) {
        .odometer;
        .position;
      }

    case .tripEnergy:
      return obdCommandPacket(packetType) {
        .batteryVoltage;
        .batteryCurrent;
      }

    case .tripData:
      return obdCommandPacket(.tripData) {
        .odometer;
        .batteryStateOfCharge;
        .batteryTemperature;
        canbusNormalAddressing;
        .batteryDistanceToEmpty;
        canbusExtendedAddressing;
      }

    case .tripWeather:
      return obdCommandPacket(.tripWeather) {
        .weather
      }

    case .acChargeStarting, .dcChargeStarting:
      return obdCommandPacket(packetType) {
        .weather;
        .odometer;
        .batteryStateOfCharge;
        .batteryTemperature;
        .batteryOriginalCapacity;
        canbusNormalAddressing;
        .batteryCurrentCapacity;
        .batteryDistanceToEmpty;
        canbusExtendedAddressing;
        .position;
      }

    case .acChargeInProgress, .dcChargeInProgress:
      return obdCommandPacket(packetType) {
        packetType == .acChargeInProgress ? .acChargerStatus : .dcChargerStatus;
      }

    case .acChargeUpdate, .dcChargeUpdate:
      return obdCommandPacket(packetType) {
        .batteryStateOfCharge;
        .batteryTemperature;
        canbusNormalAddressing;
        .batteryDistanceToEmpty;
        canbusExtendedAddressing;
      }

    case .acChargeEnding, .dcChargeEnding:
      return obdCommandPacket(packetType) {
        .batteryStateOfCharge;
        .batteryTemperature;
        .batteryOriginalCapacity;
        .batteryOriginalCapacity;
        canbusNormalAddressing;
        .batteryCurrentCapacity;
        .batteryDistanceToEmpty;
        canbusExtendedAddressing;
      }

    case .acChargeHistory, .dcChargeHistory:
      return obdCommandPacket(packetType) {
        .batteryStateOfCharge;
        .batteryTemperature;
        canbusNormalAddressing;
        .batteryDistanceToEmpty;
        canbusExtendedAddressing;
      }

    case .acChargeEnergy:
      return obdCommandPacket(packetType) {
        .batteryVoltage;
        .batteryCurrent;
      }

    case .dcChargeEnergy:
      return obdCommandPacket(packetType) {
        .batteryVoltage;
        .batteryCurrent;
      }

    default:
      DokoLogging.shared.postLoggingResponse(.error("VWE.translateDokoCommandPacket: no packet translation for '\(packetType.description)'"))
      return nil
    }
  }
}

/*
 01:54.037 .speed(?): ?
 Type: Error | Timestamp: 2026-05-08 11:01:54.037760-04:00 | Process: Pankuzu | Library: Pankuzu.debug.dylib | Subsystem: com.unchan.doko | Category: ObdLinkManager | TID: 0x2e9331
 */
