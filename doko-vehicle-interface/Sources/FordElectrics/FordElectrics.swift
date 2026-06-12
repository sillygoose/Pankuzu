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

public actor FordElectrics: ConnectedVehicleInterface {
  let logger = Logger(subsystem: "com.unchan.doko", category: "FordElectrics")

  nonisolated public let vehicle: Vehicle?
  nonisolated public let name: String = "FordElectrics"

  public var hvBatteryPower: Double?
  public var hvBatteryEnergy: Double?
  public var previousHvBatteryPower: Double?
  public var previousHvBatteryPowerUpdate: Date?

  public var chargerInputPower: Double?
  public var chargerInputEnergy: Double?
  public var previousChargerInputPower: Double?
  public var previousChargerInputPowerUpdate: Date?

  public var chargerOutputPower: Double?
  public var previousChargerOutputPower: Double?
  public var chargerOutputEnergy: Double?
  public var previousChargerOutputPowerUpdate: Date?

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
    case .gearSelected:                   obdLinkCommand = "STPX h:7E2, d:221E12"
    case .acChargerCouplerTemperature:    obdLinkCommand = "STPX h:7E2, d:224888"
    case .dcChargerCouplerTemperature:    obdLinkCommand = "STPX h:7E2, d:224897"
//    case .dcChargerCouplerTemperature3:    obdLinkCommand = "STPX h:7E2, d:2248A4"

    case .batteryEnergyToEmpty:           obdLinkCommand = "STPX h:7E4, d:224848"
    case .batteryStateOfCharge:           obdLinkCommand = "STPX h:7E4, d:224845"
    case .batteryStateOfHealth:           obdLinkCommand = "STPX h:7E4, d:22490C"
    case .batteryTemperature:             obdLinkCommand = "STPX h:7E4, d:224800"

    case .batteryVoltage:                 obdLinkCommand = "STPX h:7E4, d:22480D"
    case .batteryCurrent:                 obdLinkCommand = "STPX h:7E4, d:2248F9"

    case .acChargerStatus:                obdLinkCommand = "STPX h:7E4, d:22484F"
    case .dcChargerStatus:                obdLinkCommand = "STPX h:7E4, d:22489E"

    case .chargerInputVoltage:            obdLinkCommand = "STPX h:7E2, d:22485E"
    case .chargerInputCurrent:            obdLinkCommand = "STPX h:7E2, d:22485F"
    case .chargerOutputVoltage:           obdLinkCommand = "STPX h:7E4, d:22484A"
    case .chargerOutputCurrent:           obdLinkCommand = "STPX h:7E4, d:224850"

    case .odometer:                       obdLinkCommand = "01A6"
    case .speed:                          obdLinkCommand = "STPX h:7E0, d:221505"

    case .position:                       obdLinkCommand = ""
    case .weather:                        obdLinkCommand = ""

    default:                              obdLinkCommand = nil
    }
    guard let obdLinkCommand else {
      DokoLogging.shared.postLoggingResponse(.error("FE.vehicleObdCommand: \(command.description) not found"))
      return nil
    }
    return obdLinkCommand
  }

  private let acChargerCouplerTemperature = CommandGroup(commands: [.acChargerCouplerTemperature])
  private let dcChargerCouplerTemperature = CommandGroup(commands: [.dcChargerCouplerTemperature, .dcChargerCouplerTemperature])

  public func translateDokoCommandPacket(using packetType: DokoPacketType) async -> ObdCommandPacket? {
    switch packetType {
    case .vehicleCustomization:
      return obdCommandPacket(packetType) {
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
        packetType == .acChargeStarting ? acChargerCouplerTemperature : dcChargerCouplerTemperature;
      }
      
    case .acChargeInProgress, .dcChargeInProgress:
      return obdCommandPacket(packetType) {
        packetType == .acChargeInProgress ? .acChargerStatus : .dcChargerStatus;
      }

      //### power needed?
    case .acChargeUpdate, .dcChargeUpdate:
      return obdCommandPacket(packetType) {
        .batteryVoltage;
        .batteryCurrent;
        .batteryStateOfCharge;
        .batteryTemperature;
        packetType == .acChargeStarting ? acChargerCouplerTemperature : dcChargerCouplerTemperature;
      }

    case .acChargeEnding, .dcChargeEnding:
      return obdCommandPacket(packetType) {
        .batteryStateOfCharge;
        .batteryEnergyToEmpty;
        .batteryTemperature;
        .batteryStateOfHealth;
        packetType == .acChargeStarting ? acChargerCouplerTemperature : dcChargerCouplerTemperature;
      }

    case .acChargeHistory, .dcChargeHistory:
      return obdCommandPacket(packetType) {
        .batteryStateOfCharge;
        .batteryEnergyToEmpty;
        .batteryTemperature;
        packetType == .acChargeStarting ? acChargerCouplerTemperature : dcChargerCouplerTemperature;
      }

    case .tripEnergy:
      return obdCommandPacket(packetType) {
        .batteryVoltage;
        .batteryCurrent;
      }

    case .acChargeEnergy:
      return obdCommandPacket(packetType) {
        .batteryVoltage;
        .batteryCurrent;
        .chargerInputVoltage;
        .chargerInputCurrent;
        .chargerOutputVoltage;
        .chargerOutputCurrent;
      }

    case .dcChargeEnergy:
      return obdCommandPacket(packetType) {
        .batteryVoltage;
        .batteryCurrent;
      }

    default:
      DokoLogging.shared.postLoggingResponse(.error("FE.translateDokoCommandPacket: no packet translation for '\(packetType.description)'"))
      return nil
    }
  }
}
