import Foundation
import CoreLocation

import DokoTypes

public enum ObdCommand: Equatable, Sendable {
  case atz
  case ate0
  case ath0
  case atcaf1
  case ats0
  case atsp0
  case stcsegr1
  case stprs
  
  case extendedDiagnosticSession
  case testerPresent
  
  case vin
  case odometer, obdOdometer

  case gearSelected
  case distanceToEmpty

  case energyToEmpty
  case stateOfCharge
  case stateOfHealth
  case batteryTemperature
  case batteryVoltage
  case batteryCurrent

  case acChargerStatus
  case acChargerCouplerTemperature

  case dcChargerStatus
  case dcChargerCouplerTemperature

  // Non-OBDLink macros
  case position
  case weather
  case meanTemperature

  public var description: String {
    return self.key
  }
  
  public var key: String {
    get {
      switch self {
      case .atz:
        return ".atz"
      case .ate0:
        return ".ate0"
      case .ath0:
        return ".ath0"
      case .atcaf1:
        return ".atcaf1"
      case .ats0:
        return ".ats0"
      case .atsp0:
        return ".atsp0"
      case .stcsegr1:
        return ".stcsegr1"
      case .stprs:
        return ".stprs"
      case .extendedDiagnosticSession:
        return ".extendedDiagnosticSession"
      case .testerPresent:
        return ".testerPresent"
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
      case .batteryCurrent:
        return ".batteryCurrent"
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
      case .meanTemperature:
        return ".meanTemperature"
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
  case ate0
  case ath0
  case atcaf1
  case ats0
  case atsp0
  case stprs(String)
  case stcsegr1
  
  case extendedDiagnosticSession
  case testerPresent
  
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
  case batteryCurrent(Double)

  case acChargerStatus(Bool)
  case acChargerCouplerTemperature(Double)

  case dcChargerStatus(Bool)
  case dcChargerCouplerTemperature(Double)

  case position(DokoPosition)
  case weather(DokoCurrentWeather)
  case meanTemperature(Double)

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
      case .ate0:
        return ".ate0"
      case .ath0:
        return ".ath0"
      case .atcaf1:
        return ".atcaf1"
      case .ats0:
        return ".ats0"
      case .atsp0:
        return ".atsp0"
      case .stprs(let pstring):
        return ".stprs(\(pstring))"
      case .stcsegr1:
        return ".stcsegr1"
        
      case .extendedDiagnosticSession:
        return ".extendedDiagnosticSession"
      case .testerPresent:
        return ".testerPresent"

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
      case .batteryCurrent(let current):
        return String(format: ".batteryCurrent(%.1f)", current)

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
      case let .meanTemperature(temp):
        return ".meanTemperature(\(String(format: "%.0f℃", temp)))"
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
    self.queuedAt = Date.now
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
    self.queuedAt = queuedAt
    self.completedAt = Date.now
    self.type = type
    self.errors = errors
    self.responses = responses
  }
}
