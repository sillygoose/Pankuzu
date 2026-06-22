import Foundation
import CoreLocation

import Dependencies

import DokoTypes

public enum ObdCommand: Equatable, Hashable, Sendable {
  case atz
  case atd
  case ate(Bool)
  case ath(Bool)
  case atcfc(Bool)
  case atfcsh(String)
  case atfcsm(Int)
  case atfcsd(String)
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
  case odometer
  case speed
  case gearSelected
  
  case batteryDistanceToEmpty
  case batteryEnergyToEmpty
  case batteryStateOfCharge
  case batteryStateOfHealth
  case batteryTemperature
  case batteryOriginalCapacity
  case batteryCurrentCapacity
  
  case batteryVoltage
  case batteryCurrent
  case batteryChargeVoltageRequested
  case batteryChargeCurrentRequested
  
  case chargerInputVoltage
  case chargerInputCurrent
  case chargerOutputVoltage
  case chargerOutputCurrent

  case acChargerStatus
  case acChargerCouplerTemperature

  case dcChargerStatus
  case dcChargerCouplerTemperature1
  case dcChargerCouplerTemperature3

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
      case .atcfc(let enabled):
        return ".atcfc(\(enabled))"
      case .atfcsm(let enabled):
        return ".atfcsm(\(enabled))"
      case .atfcsh(let header):
        return ".atfcsh(\(header))"
      case .atfcsd(let data):
        return ".atfcsd(\(data))"
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
      case .speed:
        return ".speed"

      case .gearSelected:
        return ".gearSelected"
      case .batteryDistanceToEmpty:
        return ".batteryDistanceToEmpty"
      case .batteryEnergyToEmpty:
        return ".batteryEnergyToEmpty"
      case .batteryStateOfCharge:
        return ".batteryStateOfCharge"
      case .batteryStateOfHealth:
        return ".batteryStateOfHealth"
      case .batteryTemperature:
        return ".batteryTemperature"
      case .batteryOriginalCapacity:
        return ".batteryOriginalCapacity"
      case .batteryCurrentCapacity:
        return ".batteryCurrentCapacity"

      case .batteryVoltage:
        return ".batteryVoltage"
      case .batteryCurrent:
        return ".batteryCurrent"
      case .batteryChargeVoltageRequested:
        return ".batteryChargeVoltageRequested"
      case .batteryChargeCurrentRequested:
        return ".batteryChargeCurrentRequested"

      case .chargerInputCurrent:
        return ".chargerInputCurrent"
      case .chargerInputVoltage:
        return ".chargerInputVoltage"
      case .chargerOutputCurrent:
        return ".chargerOutputCurrent"
      case .chargerOutputVoltage:
        return ".chargerOutputVoltage"

      case .acChargerStatus:
        return ".acChargerStatus"
      case .acChargerCouplerTemperature:
        return ".acChargerCouplerTemperature"
      case .dcChargerStatus:
        return ".dcChargerStatus"
      case .dcChargerCouplerTemperature1:
        return ".dcChargerCouplerTemperature1"
      case .dcChargerCouplerTemperature3:
        return ".dcChargerCouplerTemperature3"
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
  case atcfc(Bool)
  case atfcsh(String)
  case atfcsm(Int)
  case atfcsd(String)
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
  case speed(Double)
  case gearSelected(Bool)

  case batteryDistanceToEmpty(Double)
  case batteryEnergyToEmpty(Double)
    case batteryStateOfCharge(Double)
  case batteryStateOfHealth(Double)
  case batteryTemperature(Double)
  case batteryOriginalCapacity(Double)
  case batteryCurrentCapacity(Double)

  case batteryVoltage(Double)
  case batteryCurrent(Double)
  case batteryChargeVoltageRequested(Double)
  case batteryChargeCurrentRequested(Double)

  case chargerInputVoltage(Double)
  case chargerInputCurrent(Double)
  case chargerOutputVoltage(Double)
  case chargerOutputCurrent(Double)

  case acChargerStatus(Bool)
  case acChargerCouplerTemperature(Double)

  case dcChargerStatus(Bool)
  case dcChargerCouplerTemperature1(Double)
  case dcChargerCouplerTemperature3(Double)

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
      case .atcfc(let enabled):
        return ".atcfc(\(enabled))"
      case .atfcsm(let enabled):
        return ".atfcsm(\(enabled))"
      case .atfcsh(let header):
        return ".atfcsh(\(header))"
      case .atfcsd(let data):
        return ".atfcsd(\(data))"
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
      case .speed(let speed):
        return String(format: ".speed(%.1f)", speed)
      case .gearSelected(let gear):
        return ".gearSelected(\(gear))"

      case .batteryDistanceToEmpty(let dte):
        return String(format: ".batteryDistanceToEmpty(%.0f)", dte)
      case .batteryEnergyToEmpty(let ete):
        return String(format: ".batteryEnergyToEmpty(%.3f)", ete)
      case .batteryStateOfCharge(let soc):
        return String(format: ".batteryStateOfCharge(%.1f)", soc)
      case .batteryStateOfHealth(let soh):
        return String(format: ".batteryStateOfHealth(%.1f)", soh)
      case .batteryTemperature(let temperature):
        return String(format: ".batteryTemperature(%.0f℃)", temperature)
      case .batteryOriginalCapacity(let kwh):
        return String(format: ".batteryOriginalCapacity(%.1f)", kwh)
      case .batteryCurrentCapacity(let kwh):
        return String(format: ".batteryCurrentCapacity(%.1f)", kwh)

      case .batteryVoltage(let voltage):
        return String(format: ".batteryVoltage(%.1f)", voltage)
      case .batteryCurrent(let current):
        return String(format: ".batteryCurrent(%.1f)", current)
      case .batteryChargeVoltageRequested(let voltage):
        return String(format: ".batteryChargeVoltageRequested(%.1f)", voltage)
      case .batteryChargeCurrentRequested(let current):
        return String(format: ".batteryChargeCurrentRequested(%.1f)", current)

      case .chargerInputVoltage(let voltage):
        return String(format: ".chargerInputVoltage(%.1fV)", voltage)
      case .chargerInputCurrent(let current):
        return String(format: ".chargerInputCurrent(%.1fA)", current)
      case .chargerOutputVoltage(let voltage):
        return String(format: ".chargerOutputVoltage(%.1fV)", voltage)
      case .chargerOutputCurrent(let current):
        return String(format: ".chargerOutputCurrent(%.1fA)", current)

      case .acChargerStatus(let status):
        return ".acChargerStatus(\(status))"
      case .acChargerCouplerTemperature(let temperature):
        return String(format: ".acChargerCouplerTemperature(%.0f℃)", temperature)

      case let .dcChargerStatus(status):
        return ".dcChargerStatus(\(status))"
      case let .dcChargerCouplerTemperature1(temperature):
        return String(format: ".dcChargerCouplerTemperature1(%.0f℃)", temperature)
      case let .dcChargerCouplerTemperature3(temperature):
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
