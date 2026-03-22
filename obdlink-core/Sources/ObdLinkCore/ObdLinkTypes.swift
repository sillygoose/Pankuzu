import Foundation
import CoreLocation

import Dependencies

import DokoTypes

public enum ObdCommand: Equatable, Hashable, Sendable {
  case atz
  case atd
  case ate(Bool)
  case ath(Bool)
  case atcaf(Bool)
  case ats(Bool)
  case atsp(Int)
  case atsh(String)
  case atcp(String)
  case atcf(String)
  case atcra(String)
  case atcm(String)

  case stp(Int)
  case stpbr(Int)
  case stpo
  case stcsegr(Bool)
  case stprs
  case stpx(Int, Int)

  case vin
  case odometer, obdOdometer

  case gearSelected
  case distanceToEmpty

  case energyToEmpty
  case stateOfCharge
  case stateOfHealth
  case batteryTemperature
  case batteryVoltage
  case batteryVoltage0
  case batteryVoltage1
  case batteryVoltage2
  case batteryVoltage3
  case batteryVoltage4
  case batteryVoltage5
  case batteryVoltage6
  case batteryVoltage7
  case batteryCurrent
  case batteryCurrent0
  case batteryCurrent1
  case batteryCurrent2
  case batteryCurrent3
  case batteryCurrent4
  case batteryCurrent5
  case batteryCurrent6
  case batteryCurrent7

  case acChargerStatus
  case acChargerCouplerTemperature

  case dcChargerStatus
  case dcChargerCouplerTemperature

  /* Non-OBDLink macros */
  case position
  case weather

  public var description: String {
    return self.key
  }
  
  public var key: String {
    get {
      switch self {
      case .atz:
        return ".atz"
      case .atd:
        return ".atd"
      case .ate(let enabled):
        return ".ate(\(enabled))"
      case .ath(let enabled):
        return ".ath(\(enabled))"
      case .atcaf(let enabled):
        return ".atcaf(\(enabled))"
      case .ats(let enabled):
        return ".ats(\(enabled))"
      case .atsp(let canProtocol):
        return ".atsp(\(canProtocol))"
      case .atcp(let priority):
        return ".atcp(\(priority))"
      case .atsh(let header):
        return ".atsh(\(header))"
      case .atcf(let filter):
        return ".atcf(\(filter))"
      case .atcra(let pattern):
        return ".atcra(\(pattern))"
      case .atcm(let mask):
        return ".atcm(\(mask))"
      case .stp(let canProtocol):
        return ".stp(\(canProtocol))"
      case .stpbr(let baudRate):
        return ".stpbr(\(baudRate))"
      case .stpo:
        return ".stpo"
      case .stcsegr(let enabled):
        return ".stcsegr(\(enabled))"
      case .stprs:
        return ".stprs"
      case .stpx(let header, let did):
        return String(format: ".stpx(h:%X, d:22%X)", header, did)

      case .vin:
        return ".vin"
      case .odometer:
        return ".odometer"
      case .obdOdometer:
        return ".obdOdometer"
      case .gearSelected:
        return ".gearSelected"
      case .distanceToEmpty:
        return ".distanceToEmpty"
      case .energyToEmpty:
        return ".energyToEmpty"
      case .stateOfCharge:
        return ".stateOfCharge"
      case .stateOfHealth:
        return ".stateOfHealth"
      case .batteryTemperature:
        return ".batteryTemperature"
      case .batteryVoltage:
        return ".batteryVoltage"
      case .batteryVoltage0:
        return ".batteryVoltage0"
      case .batteryVoltage1:
        return ".batteryVoltage1"
      case .batteryVoltage2:
        return ".batteryVoltage2"
      case .batteryVoltage3:
        return ".batteryVoltage3"
      case .batteryVoltage4:
        return ".batteryVoltage4"
      case .batteryVoltage5:
        return ".batteryVoltage5"
      case .batteryVoltage6:
        return ".batteryVoltage6"
      case .batteryVoltage7:
        return ".batteryVoltage7"
      case .batteryCurrent:
        return ".batteryCurrent"
      case .batteryCurrent0:
        return ".batteryCurrent0"
      case .batteryCurrent1:
        return ".batteryCurrent1"
      case .batteryCurrent2:
        return ".batteryCurrent2"
      case .batteryCurrent3:
        return ".batteryCurrent3"
      case .batteryCurrent4:
        return ".batteryCurrent4"
      case .batteryCurrent5:
        return ".batteryCurrent5"
      case .batteryCurrent6:
        return ".batteryCurrent6"
      case .batteryCurrent7:
        return ".batteryCurrent7"
      case .acChargerStatus:
        return ".acChargerStatus"
      case .acChargerCouplerTemperature:
        return ".acChargerCouplerTemperature"
      case .dcChargerStatus:
        return ".dcChargerStatus"
      case .dcChargerCouplerTemperature:
        return ".dcChargerCouplerTemperature"
      case .position:
        return ".position"
      case .weather:
        return ".weather"
      }
    }
  }
}

public enum ObdResult: Equatable, Sendable {
  case ok
  case error(String)
  case invalid
  case stopped
  case bufferFull
  case busBusy
  case busError
  case canError
  case dataError
  case noData
  case outOfMemory
  case rxError

  public static func getObdError(errorString: String) -> ObdResult {
    switch errorString {
    case "?":
      return .invalid
    case "STOPPED":
      return .stopped
    case "BUFFER FULL":
      return .bufferFull
    case "BUS BUSY":
      return .busBusy
    case "BUS ERROR":
      return .busError
    case "CAN ERROR":
      return .canError
    case "<DATA ERROR":
      return .dataError
    case "NO DATA":
      return .noData
    case "OUT OF MEMORY":
      return .outOfMemory
    case "<RX ERROR":
      return .rxError
    default:
      return .error(errorString)
    }
  }

  public var description: String {
    get {
      switch self {
      case .ok:
        return "OK"
      case .error:
        return "ERROR"
      case .invalid:
        return "?"
      case .stopped:
        return "STOPPED"
      case .bufferFull:
        return "BUFFER FULL"
      case .busBusy:
        return "BUS BUSY"
      case .busError:
        return "BUS ERROR"
      case .canError:
        return "CAN ERROR"
      case .dataError:
        return "<DATA ERROR"
      case .noData:
        return "NO DATA"
      case .outOfMemory:
        return "OUT OF MEMORY"
      case .rxError:
        return "<RX ERROR"
      }
    }
  }
}

public enum ObdResponse: Equatable, Sendable {
  case obdError(String, String)
  case info(String)
  case error(String)
  
  case atz(String)
  case atd(String)
  case ate(Bool)
  case ath(Bool)
  case atcaf(Bool)
  case ats(Bool)
  case atsp(Int)
  case atcp(String)
  case atsh(String)
  case atcf(String)
  case atcra(String)
  case atcm(String)

  case stp(Int)
  case stpbr(Int)
  case stpo(String)
  case stcsegr(Bool)
  case stprs(String)
  case stpx(String)

  case vin(String)
  case odometer(Double)
  case obdOdometer(Double)

  case gearSelected(Bool)
  case distanceToEmpty(Double)

  case energyToEmpty(Double)
  case stateOfCharge(Double)
  case stateOfHealth(Double)
  case batteryTemperature(Double)
  case batteryVoltage(Double)
  case batteryVoltage0(Double)
  case batteryVoltage1(Double)
  case batteryVoltage2(Double)
  case batteryVoltage3(Double)
  case batteryVoltage4(Double)
  case batteryVoltage5(Double)
  case batteryVoltage6(Double)
  case batteryVoltage7(Double)
  case batteryCurrent(Double)
  case batteryCurrent0(Double)
  case batteryCurrent1(Double)
  case batteryCurrent2(Double)
  case batteryCurrent3(Double)
  case batteryCurrent4(Double)
  case batteryCurrent5(Double)
  case batteryCurrent6(Double)
  case batteryCurrent7(Double)

  case acChargerStatus(Bool)
  case acChargerCouplerTemperature(Double)

  case dcChargerStatus(Bool)
  case dcChargerCouplerTemperature(Double)

  case position(DokoPosition)
  case weather(DokoCurrentWeather)

  public var description: String {
    get {
      switch self {
      case .obdError(let command, let error):
        return "\(command)(\(error))"
      case .info(let info):
        return "\(info)"
      case .error(let error):
        return "\(error)"

      case .atz:
        return ".atz"
      case .atd:
        return ".atd"
      case .ate(let enabled):
        return ".ate(\(enabled))"
      case .ath(let enabled):
        return ".ath(\(enabled))"
      case .atcaf(let enabled):
        return ".atcaf(\(enabled))"
      case .ats(let enabled):
        return ".ats(\(enabled))"
      case .atsp(let canProtocol):
        return ".atsp(\(canProtocol))"
      case .atcp(let priority):
        return ".atcp \(priority)"
      case .atsh(let header):
        return ".atsh \(header)"
      case .atcf(let filter):
        return ".atcf(\(filter))"
      case .atcra(let pattern):
        return ".atcra(\(pattern))"
      case .atcm(let mask):
        return ".atcm(\(mask))"
        
      case .stp(let canProtocol):
        return ".stp(\(canProtocol))"
      case .stpbr(let baudRate):
        return ".stpbr(\(baudRate))"
      case .stpo:
        return ".stpo"
      case .stcsegr(let enabled):
        return ".stcsegr(\(enabled))"
      case .stprs(let canProtocol):
        return ".stprs(\(canProtocol))"
      case .stpx:
        return ".stpx"

      case .vin(let vin):
        return ".vin(\(vin))"
      case .odometer(let odometer):
        return String(format: ".odometer(%.1f)", odometer)
      case .obdOdometer(let obdOdometer):
        return String(format: ".obdOdometer(%.1f)", obdOdometer)

      case .gearSelected(let gear):
        return ".gearSelected(\(gear))"
      case .distanceToEmpty(let dte):
        return String(format: ".distanceToEmpty(%.3f)", dte)

      case .energyToEmpty(let ete):
        return String(format: ".energyToEmpty(%.3f)", ete)
      case .stateOfCharge(let soc):
        return String(format: ".stateOfCharge(%.1f)", soc)
      case .stateOfHealth(let soh):
        return String(format: ".stateOfHealth(%.1f)", soh)
      case .batteryTemperature(let temperature):
        return String(format: ".batteryTemperature(%.0f℃)", temperature)
      case .batteryVoltage(let voltage):
        return String(format: ".batteryVoltage(%.1f)", voltage)
      case .batteryVoltage0(let voltage):
        return String(format: ".batteryVoltage0(%.1f)", voltage)
      case .batteryVoltage1(let voltage):
        return String(format: ".batteryVoltage1(%.1f)", voltage)
      case .batteryVoltage2(let voltage):
        return String(format: ".batteryVoltage2(%.1f)", voltage)
      case .batteryVoltage3(let voltage):
        return String(format: ".batteryVoltage3(%.1f)", voltage)
      case .batteryVoltage4(let voltage):
        return String(format: ".batteryVoltage4(%.1f)", voltage)
      case .batteryVoltage5(let voltage):
        return String(format: ".batteryVoltage5(%.1f)", voltage)
      case .batteryVoltage6(let voltage):
        return String(format: ".batteryVoltage6(%.1f)", voltage)
      case .batteryVoltage7(let voltage):
        return String(format: ".batteryVoltage7(%.1f)", voltage)
      case .batteryCurrent(let current):
        return String(format: ".batteryCurrent(%.1f)", current)
      case .batteryCurrent0(let current):
        return String(format: ".batteryCurrent0(%.1f)", current)
      case .batteryCurrent1(let current):
        return String(format: ".batteryCurrent1(%.1f)", current)
      case .batteryCurrent2(let current):
        return String(format: ".batteryCurrent2(%.1f)", current)
      case .batteryCurrent3(let current):
        return String(format: ".batteryCurrent3(%.1f)", current)
      case .batteryCurrent4(let current):
        return String(format: ".batteryCurrent4(%.1f)", current)
      case .batteryCurrent5(let current):
        return String(format: ".batteryCurrent5(%.1f)", current)
      case .batteryCurrent6(let current):
        return String(format: ".batteryCurrent6(%.1f)", current)
      case .batteryCurrent7(let current):
        return String(format: ".batteryCurrent7(%.1f)", current)

      case .acChargerStatus(let status):
        return ".acChargerStatus(\(status))"
      case .acChargerCouplerTemperature(let temperature):
        return String(format: ".acChargerCouplerTemperature(%.0f℃)", temperature)

      case let .dcChargerStatus(status):
        return ".dcChargerStatus(\(status))"
      case let .dcChargerCouplerTemperature(temperature):
        return String(format: ".dcChargerCouplerTemperature(%.0f℃)", temperature)

      case let .position(position):
        return String(format: ".position(%.5f, %.5f, %.0f)", position.latitude, position.longitude, position.elevation)
      case let .weather(weather):
        return ".weather(\(String(format: "%.0f℃", weather.temperature)), \(weather.conditionSymbol))"
      }
    }
  }
}

public struct ObdCommandResponse: Equatable, Sendable {
  public let command: ObdCommand
  public let result: ObdResult
  public let response: ObdResponse
  public let rawCommand: String
  public let rawResponse: String

  public init(command: ObdCommand, result: ObdResult, response: ObdResponse, rawCommand: String, rawResponse: String) {
    self.command = command
    self.result = result
    self.response = response
    self.rawCommand = rawCommand
    self.rawResponse = rawResponse
  }
}

public typealias ObdResponseDictionary = OrderedDictionary<ObdCommand, ObdCommandResponse>

public struct ObdCommandPacket: Equatable, Sendable {
  public let queuedAt: Date
  public let type: DokoPacketType
  public let commands: [ObdCommand]

  public init(type: DokoPacketType, commands: [ObdCommand]) {
    @Dependency(\.date.now) var now
    self.queuedAt = now
    self.type = type
    self.commands = commands
  }
}

public struct ObdResponsePacket: Equatable, Sendable {
  public let queuedAt: Date
  public let completedAt: Date
  public let type: DokoPacketType
  public var errors: Int
  public var responses: ObdResponseDictionary

  public init(queuedAt: Date, type: DokoPacketType, errors: Int, responses: ObdResponseDictionary) {
    @Dependency(\.date.now) var now
    self.queuedAt = queuedAt
    self.completedAt = now
    self.type = type
    self.errors = errors
    self.responses = responses
  }
}
