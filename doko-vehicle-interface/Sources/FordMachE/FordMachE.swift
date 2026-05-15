import OSLog

import DokoTypes
import DokoLogging
import VehicleInterface
import ObdLinkCore
import Vehicles

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
    case .stpo:                         obdLinkCommand = "STPO"
    case .stp(let canProtocol):         obdLinkCommand = "STP\(canProtocol)"
    case .stpbr(let baudRate):          obdLinkCommand = "STPBR\(baudRate)"

    case .gearSelected:                 obdLinkCommand = "STPX h:7E2, d:221E12"
    case .acChargerCouplerTemperature:  obdLinkCommand = "STPX h:7E2, d:224888"
    case .dcChargerCouplerTemperature:  obdLinkCommand = "STPX h:7E2, d:224897"

    case .batteryEnergyToEmpty:         obdLinkCommand = "STPX h:7E4, d:224848"
    case .batteryStateOfCharge:         obdLinkCommand = "STPX h:7E4, d:224845"
    case .batteryStateOfHealth:         obdLinkCommand = "STPX h:7E4, d:22490C"
    case .batteryTemperature:           obdLinkCommand = "STPX h:7E4, d:224800"
      
    case .batteryVoltage:               obdLinkCommand = "STPX h:7E4, d:22480D"
    case .batteryCurrent:               obdLinkCommand = "STPX h:7E4, d:2248F9"

    case .acChargerStatus:              obdLinkCommand = "STPX h:7E4, d:22484F"
    case .dcChargerStatus:              obdLinkCommand = "STPX h:7E4, d:22489E"

    case .odometer:                     obdLinkCommand = "STPX h:720, d:22404C"
    case .speed:                        obdLinkCommand = "STPX h:7E4, d:22F40D"

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
 
  private let canbusInitialization = CommandGroup(commands: [.stp(53), .stpbr(500000), .stpo])

  public func translateDokoCommandPacket(using packetType: DokoPacketType) async -> ObdCommandPacket? {
    switch packetType {
    case .vehicleCustomization:
      return obdCommandPacket(packetType) {
        canbusInitialization;
      }

    case .idle:
      return obdCommandPacket(packetType) {
        .gearSelected;
        .acChargerStatus;
        .dcChargerStatus;
      }

    case .tripStarting:
      return obdCommandPacket(packetType) {
        .odometer;
        .batteryStateOfCharge;
        .batteryEnergyToEmpty;
        .batteryTemperature;
        .batteryStateOfHealth;
        .position;
      }

    case .tripInProgress:
      return obdCommandPacket(packetType) {
        .gearSelected;
      }

    case .tripUpdate:
      return obdCommandPacket(packetType) {
        .position;
        .odometer;
        .batteryStateOfCharge;
        .batteryTemperature;
      }

    case .tripEnding:
      return obdCommandPacket(packetType) {
        .weather;
        .position;
        .odometer;
        .batteryStateOfCharge;
        .batteryEnergyToEmpty;
        .batteryTemperature;
        .batteryStateOfHealth;
      }

    case .tripData:
      return obdCommandPacket(packetType) {
        .odometer;
        .batteryStateOfCharge;
        .batteryEnergyToEmpty;
        .batteryTemperature;
      }

    case .tripWeather:
      return obdCommandPacket(packetType) {
        .weather
      }
      
    case .acChargeStarting, .dcChargeStarting:
      return obdCommandPacket(packetType) {
        .weather;
        .position;
        .odometer;
        .batteryStateOfCharge;
        .batteryEnergyToEmpty;
        .batteryTemperature;
        .batteryStateOfHealth;
        packetType == .acChargeStarting ? .acChargerCouplerTemperature : .dcChargerCouplerTemperature;
      }
      
    case .acChargeInProgress, .dcChargeInProgress:
      return obdCommandPacket(packetType) {
        packetType == .acChargeInProgress ? .acChargerStatus : .dcChargerStatus;
      }

    case .acChargeUpdate, .dcChargeUpdate:
      return obdCommandPacket(packetType) {
        .batteryVoltage;
        .batteryCurrent;
        .batteryStateOfCharge;
        .batteryTemperature;
        packetType == .acChargeUpdate ? .acChargerCouplerTemperature : .dcChargerCouplerTemperature;
      }

    case .acChargeEnding, .dcChargeEnding:
      return obdCommandPacket(packetType) {
        .batteryStateOfCharge;
        .batteryEnergyToEmpty;
        .batteryTemperature;
        .batteryStateOfHealth;
        packetType == .acChargeEnding ? .acChargerCouplerTemperature : .dcChargerCouplerTemperature;
      }

    case .acChargeHistory, .dcChargeHistory:
      return obdCommandPacket(packetType) {
        .batteryStateOfCharge;
        .batteryEnergyToEmpty;
        .batteryTemperature;
        packetType == .acChargeHistory ? .acChargerCouplerTemperature : .dcChargerCouplerTemperature;
      }

    case .tripEnergy, .acChargeEnergy, .dcChargeEnergy:
      return obdCommandPacket(packetType) {
        .batteryVoltage;
        .batteryCurrent;
      }

    default:
      DokoLogging.shared.postLoggingResponse(.error("FME.translateDokoCommandPacket: no packet translation for '\(packetType.description)'"))
      return nil
    }
  }
}
