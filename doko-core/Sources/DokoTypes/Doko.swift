import Foundation
import CoreLocation

import OrderedCollections

public struct EfficiencyPoint: Equatable, Identifiable, Hashable, Codable, Sendable {
  public let timestamp: Date
  public let efficiency: Double
  public var id: Date { timestamp }

  public init(timestamp: Date, efficiency: Double) {
    self.timestamp = timestamp
    self.efficiency = efficiency
  }

  // Short keys: this gets encoded once per point in efficiencyMovingAverage, and that array is
  // the dominant contributor to ContentState's size against ActivityKit's 4KB limit.
  enum CodingKeys: String, CodingKey {
    case timestamp = "t"
    case efficiency = "e"
  }
}

public struct DokoCurrentWeather: Equatable, Hashable, Codable, Sendable {
  public var timestamp: Date
  public let temperature: Double
  public let windSpeed: Double
  public let windGust: Double?
  public let windDirection: Double
  public let windCompassDirection: String
  public let conditionSymbol: String

  public init(
    timestamp: Date,
    temperature: Double,
    windSpeed: Double,
    windGust: Double? = nil,
    windDirection: Double,
    windCompassDirection: String,
    conditionSymbol: String
  ) {
    self.timestamp = timestamp
    self.temperature = (temperature * 10).rounded() / 10
    self.windSpeed =  (windSpeed * 10).rounded() / 10
    self.windGust =  windGust.map { ($0 * 10).rounded() / 10 }
    self.windDirection = windDirection
    self.windCompassDirection = windCompassDirection
    self.conditionSymbol = conditionSymbol
  }
}

public struct DokoPosition: Equatable, Hashable, Codable, Sendable {
  public var timestamp: Date
  public let latitude: Double
  public let longitude: Double
  public let elevation: Double
  public let course: Double?
  public let speed: Double?
  public let horizontalAccuracy: Double?
  public let verticalAccuracy: Double?

  public init(position: CLLocation) {
    self.timestamp = position.timestamp
    self.latitude = (position.coordinate.latitude * 1_000_000).rounded() / 1_000_000
    self.longitude = (position.coordinate.longitude * 1_000_000).rounded() / 1_000_000
    self.elevation = (position.altitude * 10).rounded() / 10
    self.course = position.course < 0 ? nil : position.course.rounded()
    self.speed = position.speed < 0 ? nil : (position.speed * 3.6).rounded()
    self.horizontalAccuracy = nil // horizontalAccuracy.flatMap { $0 < 0 ? nil : $0.rounded() }
    self.verticalAccuracy = nil   // verticalAccuracy.flatMap { $0 < 0 ? nil : $0.rounded() }
  }
}

public enum CanbusProtocol: Equatable, Hashable, Sendable {
  case iso15765_11bit
  case iso15765_29bit
  public var description: String {
    switch self {
    case .iso15765_11bit: return "‭11-bit"
    case .iso15765_29bit: return "‭29-bit"
    }
  }
}

public enum VehicleState: Equatable, Hashable, Sendable {
  case reset
  case vin, vehicleCustomization
  case idle,
       tripStarting, tripInProgress, tripEnding,
       acChargeStarting, acChargeInProgress, acChargeEnding,
       dcChargeStarting, dcChargeInProgress, dcChargeEnding
  
  public var description: String {
    switch self {
    case .reset: return ".reset"
    case .vin: return ".vin"
    case .vehicleCustomization: return ".vehicleCustomization"
    case .idle: return ".idle"
    case .tripStarting: return ".tripStarting"
    case .tripInProgress: return ".tripInProgress"
    case .tripEnding: return ".tripEnding"
    case .acChargeStarting: return ".acChargeStarting"
    case .dcChargeStarting: return ".dcChargeStarting"
    case .acChargeInProgress: return ".acChargeInProgress"
    case .dcChargeInProgress: return ".dcChargeInProgress"
    case .acChargeEnding: return ".acChargeEnding"
    case .dcChargeEnding: return ".dcChargeEnding"
    }
  }
}

public enum DokoPacketType: Equatable, Hashable, Sendable {
  case reset
  case vin
  case vehicleCustomization
  case idle

  case tripStarting, tripInProgress, tripEnergy, tripUpdate, tripEnding
  case tripCorePosition, tripCoreElevation, tripData, tripWeather

  case acChargeStarting, acChargeInProgress, acChargeEnergy, acChargeUpdate, acChargeEnding
  case dcChargeStarting, dcChargeInProgress, dcChargeEnergy, dcChargeUpdate, dcChargeEnding
  case acChargeHistory, dcChargeHistory

  public var description: String {
    switch self {
    case .reset:
      ".reset"
    case .vehicleCustomization:
      ".vehicleCustomization"
    case .vin:
      ".vin"
    case .idle:
      ".idle"

    case .tripStarting:
      ".tripStarting"
    case .tripInProgress:
      ".tripIP"
    case .tripEnergy:
      ".tripEnergy"
    case .tripUpdate:
      ".tripUpdate"
    case .tripEnding:
      ".tripEnding"
    case .tripCorePosition:
      ".tripCorePos"
    case .tripCoreElevation:
      ".tripCoreEle"
    case .tripData:
      ".tripData"
    case .tripWeather:
      ".tripWeather"

    case .acChargeStarting:
      ".acChargeStarting"
    case .acChargeInProgress:
      ".acChnProgress"
    case .acChargeEnergy:
      ".acChargeEnergy"
    case .acChargeEnding:
      ".acChargeEnding"

    case .dcChargeStarting:
      ".dcChargeStarting"
    case .dcChargeInProgress:
      ".dcChargeInProgress"
    case .dcChargeEnergy:
      ".dcChargeEnergy"
    case .dcChargeEnding:
      ".dcChargeEnding"

    case .acChargeUpdate:
      ".acChargeUpdate"
    case .dcChargeUpdate:
      ".dcChargeUpdate"

    case .acChargeHistory:
      ".acChargeHistory"
    case .dcChargeHistory:
      ".dcChargeHistory"
    }
  }
}

public typealias DokoResponseDictionary = OrderedDictionary<DokoCommand, DokoCommandResponse>

public enum DokoCommand: Equatable, Hashable, Sendable {
  case nextState
  case error
  
  case reset
  case stprs
  case vin
  case vehicleCustomization

  case idle

  case tripStarting, tripInProgress, tripUpdate, tripEnding
  case tripEnergy, tripPosition, tripData, tripWeather

  case acChargeStarting, acChargeInProgress, acChargeEnding
  case acChargeUpdate, acChargeEnergy, acChargeHistory

  case dcChargeStarting, dcChargeInProgress, dcChargeEnding
  case dcChargeUpdate, dcChargeEnergy, dcChargeHistory

  case duration
  case position
  case weather, meanTemperature
  case odometer, distance
  case speed
  
  case tripEfficiency
  case tripEfficiency5Minute, tripEfficiency10Minute, tripEfficiency15Minute, tripEfficiencyMovingAverage

  case batteryStateOfCharge
  case batteryStateOfHealth
  case batteryTemperature
  case batteryEnergyToEmpty
  case batteryDistanceToEmpty
  case batteryOriginalCapacity
  case batteryCurrentCapacity
  
  case couplerTemperature
  case primaryCouplerTemperature
  case secondaryCouplerTemperature

  case batteryVoltage
  case batteryCurrent
  case batteryPower
  case batteryEnergy
  case batteryChargeVoltageRequested
  case batteryChargeCurrentRequested

  case chargerInputVoltage
  case chargerInputCurrent
  case chargerInputPower
  case chargerInputEnergy
  case chargerInputPeakPower

  case chargerOutputVoltage
  case chargerOutputCurrent
  case chargerOutputPower
  case chargerOutputEnergy

  public var description: String {
    return self.key
  }
  
  public var key: String {
    get {
      switch self {
      case .nextState:
        return ".nextState"
      case .error:
        return ".error"

      case .reset:
        return ".reset"
      case .stprs:
        return ".stprs"
      case .vin:
        return ".vin"
      case .vehicleCustomization:
        return ".vehicleCustomization"

      case .idle:
        return ".idle"

      case .tripStarting:
        return ".tripStarting"
      case .tripInProgress:
        return ".tripInProgress"
      case .tripUpdate:
        return ".tripUpdate"
      case .tripEnding:
        return ".tripEnding"
      case .tripEnergy:
        return ".tripEnergy"
      case .tripPosition:
        return ".tripPosition"
      case .tripData:
        return ".tripData"
      case .tripWeather:
        return ".tripWeather"

      case .acChargeStarting:
        return ".acChargeStarting"
      case .acChargeInProgress:
        return ".acChargeInProgress"
      case .acChargeUpdate:
        return ".acChargeUpdate"
      case .acChargeEnding:
        return ".acChargeEnding"
      case .acChargeEnergy:
        return ".acChargeEnergy"
      case .acChargeHistory:
        return ".acChargeHistory"

      case .dcChargeStarting:
        return ".dcChargeStarting"
      case .dcChargeInProgress:
        return ".dcChargeInProgress"
      case .dcChargeUpdate:
        return ".dcChargeUpdate"
      case .dcChargeEnding:
        return ".dcChargeEnding"
      case .dcChargeEnergy:
        return ".dcChargeEnergy"
      case .dcChargeHistory:
        return ".dcChargeHistory"

      case .duration:
        return ".duration"
      case .position:
        return ".position"
      case .weather:
        return ".weather"
      case .meanTemperature:
        return ".meanTemperature"
      case .odometer:
        return ".odometer"
      case .distance:
        return ".distance"
      case .speed:
        return ".speed"

      case .tripEfficiency:
        return ".tripEfficiency"
      case .tripEfficiency5Minute:
        return ".tripEfficiency5Minute"
      case .tripEfficiency10Minute:
        return ".tripEfficiency10Minute"
      case .tripEfficiency15Minute:
        return ".tripEfficiency15Minute"
      case .tripEfficiencyMovingAverage:
        return ".tripEfficiencyMovingAverage"

      case .batteryStateOfCharge:
        return ".batteryStateOfCharge"
      case .batteryStateOfHealth:
        return ".batteryStateOfHealth"
      case .batteryTemperature:
        return ".batteryTemperature"
      case .batteryEnergyToEmpty:
        return ".batteryEnergyToEmpty"
      case .batteryDistanceToEmpty:
        return ".batteryDistanceToEmpty"
      case .batteryOriginalCapacity:
        return ".batteryOriginalCapacity"
      case .batteryCurrentCapacity:
        return ".batteryCurrentCapacity"
        
      case .batteryVoltage:
        return ".batteryVoltage"
      case .batteryCurrent:
        return ".batteryCurrent"
      case .batteryPower:
        return ".batteryPower"
      case .batteryEnergy:
        return ".batteryEnergy"
      case .batteryChargeVoltageRequested:
        return ".batteryChargeVoltageRequested"
      case .batteryChargeCurrentRequested:
        return ".batteryChargeCurrentRequested"

      case .couplerTemperature:
        return ".couplerTemperature"
      case .primaryCouplerTemperature:
        return ".primaryCouplerTemperature"
      case .secondaryCouplerTemperature:
        return ".secondaryCouplerTemperature"

      case .chargerInputCurrent:
        return ".chargerInputCurrent"
      case .chargerInputVoltage:
        return ".chargerInputVoltage"
      case .chargerInputPower:
        return ".chargerInputPeakPower"
      case .chargerInputEnergy:
        return ".chargerInputEnergy"
      case .chargerInputPeakPower:
        return ".chargerInputPeakPower"

      case .chargerOutputCurrent:
        return ".chargerOutputCurrent"
      case .chargerOutputVoltage:
        return ".chargerOutputVoltage"
      case .chargerOutputPower:
        return ".chargerOutputPower"
      case .chargerOutputEnergy:
        return ".chargerOutputEnergy"
      }
    }
  }
}

public struct DokoCommandResponse: Equatable, Sendable {
  public let command: DokoCommand
  public let response: DokoResponse

  public init(command: DokoCommand, response: DokoResponse) {
    self.command = command
    self.response = response
  }
}

public enum DokoResponse: Equatable, Sendable {
  case nextState(VehicleState)
  case error(String)
  
  case reset(String)
  case stprs(String)
  case vin(String)

  case duration(Double)
  case position(DokoPosition)
  case weather(DokoCurrentWeather)
  case meanTemperature(Double)
  case odometer(Double)
  case distance(Double)
  case speed(Double)
  
  case tripEfficiency(Double)
  case tripEfficiency5Minute(Double), tripEfficiency10Minute(Double), tripEfficiency15Minute(Double)
  case tripEfficiencyMovingAverage([EfficiencyPoint])

  case batteryStateOfCharge(Double)
  case batteryStateOfHealth(Double)
  case batteryTemperature(Double)
  case batteryEnergyToEmpty(Double)
  case batteryDistanceToEmpty(Double)
  case batteryOriginalCapacity(Double)
  case batteryCurrentCapacity(Double)

  case couplerTemperature(Double)
  case primaryCouplerTemperature(Double)
  case secondaryCouplerTemperature(Double)

  case batteryVoltage(Double)
  case batteryCurrent(Double)
  case batteryPower(Double)
  case batteryEnergy(Double)
  case batteryChargeVoltageRequested(Double)
  case batteryChargeCurrentRequested(Double)

  case chargerInputVoltage(Double)
  case chargerInputCurrent(Double)
  case chargerInputPower(Double)
  case chargerInputEnergy(Double)
  case chargerInputPeakPower(Double)

  case chargerOutputVoltage(Double)
  case chargerOutputCurrent(Double)
  case chargerOutputPower(Double)
  case chargerOutputEnergy(Double)

  public var description: String {
    get {
      switch self {
      case .nextState(let newState):
        return ".nextState(\(newState))"
      case .error(let error):
        return ".error(\(error))"

      case .reset(let version):
        return ".reset(\(version))"
      case .stprs(let protocolString):
        return ".stprs(\(protocolString))"
      case .vin(let vin):
        return ".vin(\(vin))"

      case let .duration(duration):
        return String(format: ".duration(%.0fs)", duration)
      case let .position(position):
        return String(format: ".position(%.5f, %.5f, %.0f)", position.latitude, position.longitude, position.elevation)
      case let .weather(weather):
        return ".weather(\(String(format: "%.0f℃", weather.temperature)), \(weather.conditionSymbol), \(String(format: "%.0f", weather.windSpeed)))"
      case let .meanTemperature(temp):
        return ".meanTemperature(\(String(format: "%.0f℃", temp)))"
      case .odometer(let odometer):
        return String(format: ".odometer(%.1fkm)", odometer)
      case .distance(let distance):
        return String(format: ".distance(%.1fkm)", distance)
      case .speed(let speed):
        return String(format: ".speed(%.1fkph)", speed)
        
      case .tripEfficiency(let efficiency):
        return String(format: ".tripEfficiency(%.1fkm/kWh)", efficiency)
      case .tripEfficiency5Minute(let efficiency):
        return String(format: ".tripEfficiency5Minute(%.1fkm/kWh)", efficiency)
      case .tripEfficiency10Minute(let efficiency):
        return String(format: ".tripEfficiency10Minute(%.1fkm/kWh)", efficiency)
      case .tripEfficiency15Minute(let efficiency):
        return String(format: ".tripEfficiency15Minute(%.1fkm/kWh)", efficiency)
      case .tripEfficiencyMovingAverage(let efficiencyMovingAverage):
        return String(format: ".tripEfficiencyMovingAverage(\(efficiencyMovingAverage.count))")

      case .batteryStateOfCharge(let soc):
        return String(format: ".batteryStateOfCharge(%.1f%)", soc)
      case .batteryStateOfHealth(let soh):
        return String(format: ".batteryStateOfHealth(%.1f%)", soh)
      case .batteryTemperature(let temp):
        return String(format: ".batteryTemperature(%.0f℃)", temp)
      case .batteryEnergyToEmpty(let ete):
        return String(format: ".batteryEnergyToEmpty(%.1fkWh)", ete)
      case .batteryDistanceToEmpty(let dte):
        return String(format: ".batteryDistanceToEmpty(%.0fkm)", dte)
      case .batteryOriginalCapacity(let kwh):
        return String(format: ".batteryOriginalCapacity(%.1fkWh)", kwh)
      case .batteryCurrentCapacity(let kwh):
        return String(format: ".batteryCurrentCapacity(%.1fkWh)", kwh)

      case .batteryVoltage(let voltage):
        return String(format: ".batteryVoltage(%.1fV)", voltage)
      case .batteryCurrent(let current):
        return String(format: ".batteryCurrent(%.1fA)", current)
      case .batteryPower(let power):
        return String(format: ".batteryPower(%.1fkW)", power)
      case .batteryEnergy(let energy):
        return String(format: ".batteryEnergy(%.3fkWh)", energy)
      case .batteryChargeVoltageRequested(let voltage):
        return String(format: ".batteryChargeVoltageRequested(%.1fV)", voltage)
      case .batteryChargeCurrentRequested(let current):
        return String(format: ".batteryChargeCurrentRequested(%.1fA)", current)

      case .couplerTemperature(let temp):
        return String(format: ".couplerTemperature(%.0f℃)", temp)
      case .primaryCouplerTemperature(let temp):
        return String(format: ".primaryCouplerTemperature(%.0f℃)", temp)
      case .secondaryCouplerTemperature(let temp):
        return String(format: ".secondaryCouplerTemperature(%.0f℃)", temp)

      case .chargerInputVoltage(let voltage):
        return String(format: ".chargerInputVoltage(%.1fV)", voltage)
      case .chargerInputCurrent(let current):
        return String(format: ".chargerInputCurrent(%.1fA)", current)
      case .chargerInputPower(let power):
        return String(format: ".chargerInputPower(%.1fkW)", power)
      case .chargerInputEnergy(let energy):
        return String(format: ".chargerInputEnergy(%.3fkWh)", energy)
      case .chargerInputPeakPower(let power):
        return String(format: ".chargerInputPeakPower(%.1fkW)", power)

      case .chargerOutputVoltage(let voltage):
        return String(format: ".chargerOutputVoltage(%.1fV)", voltage)
      case .chargerOutputCurrent(let current):
        return String(format: ".chargerOutputCurrent(%.1fA)", current)
      case .chargerOutputPower(let power):
        return String(format: ".chargerOutputPower(%.1fkW)", power)
      case .chargerOutputEnergy(let energy):
        return String(format: ".chargerOutputEnergy(%.3fkWh)", energy)
      }
    }
  }
}

public struct DokoResponsePacket: Equatable, Sendable {
  public let completedAt: Date
  public let type: DokoPacketType
  public var responses: DokoResponseDictionary

  public init(type: DokoPacketType, responses: DokoResponseDictionary) {
    self.completedAt = Date.now
    self.type = type
    self.responses = responses
  }
}

extension DokoResponsePacket {
  public var nextState: VehicleState? {
    guard case let .nextState(v)? = responses[.nextState]?.response else { return nil }
    return v
  }

  public var vin: String? {
    guard case let .vin(v)? = responses[.vin]?.response else { return nil }
    return v
  }

  public var duration: Double? {
    guard case let .duration(v)? = responses[.duration]?.response else { return nil }
    return v
  }

  public var odometer: Double? {
    guard case let .odometer(v)? = responses[.odometer]?.response else { return nil }
    return v
  }

  public var distance: Double? {
    guard case let .distance(v)? = responses[.distance]?.response else { return nil }
    return v
  }

  public var speed: Double? {
    guard case let .speed(v)? = responses[.speed]?.response else { return nil }
    return v
  }

  public var tripEfficiency: Double? {
    guard case let .tripEfficiency(v)? = responses[.tripEfficiency]?.response else { return nil }
    return v
  }

  public var tripEfficiency5Minute: Double? {
    guard case let .tripEfficiency5Minute(v)? = responses[.tripEfficiency5Minute]?.response else { return nil }
    return v
  }

  public var tripEfficiency10Minute: Double? {
    guard case let .tripEfficiency10Minute(v)? = responses[.tripEfficiency10Minute]?.response else { return nil }
    return v
  }

  public var tripEfficiencyMovingAverage: [EfficiencyPoint] {
    guard case let .tripEfficiencyMovingAverage(v)? = responses[.tripEfficiencyMovingAverage]?.response else { return [] }
    return v
  }

  public var tripEfficiency15Minute: Double? {
    guard case let .tripEfficiency15Minute(v)? = responses[.tripEfficiency15Minute]?.response else { return nil }
    return v
  }

  public var position: DokoPosition? {
    guard case let .position(v)? = responses[.position]?.response else { return nil }
    return v
  }

  public var weather: DokoCurrentWeather? {
    guard case let .weather(v)? = responses[.weather]?.response else { return nil }
    return v
  }
  
  public var meanTemperature: Double? {
    guard case let .meanTemperature(v)? = responses[.meanTemperature]?.response else { return nil }
    return v
  }
  
  public var batteryDistanceToEmpty: Double? {
    guard case let .batteryDistanceToEmpty(v)? = responses[.batteryDistanceToEmpty]?.response else { return nil }
    return v
  }

  public var batteryEnergyToEmpty: Double? {
    guard case let .batteryEnergyToEmpty(v)? = responses[.batteryEnergyToEmpty]?.response else { return nil }
    return v
  }

  public var batteryStateOfCharge: Double? {
    guard case let .batteryStateOfCharge(v)? = responses[.batteryStateOfCharge]?.response else { return nil }
    return v
  }

  public var batteryStateOfHealth: Double? {
    guard case let .batteryStateOfHealth(v)? = responses[.batteryStateOfHealth]?.response else { return nil }
    return v
  }

  public var batteryTemperature: Double? {
    guard case let .batteryTemperature(v)? = responses[.batteryTemperature]?.response else { return nil }
    return v
  }

  public var batteryOriginalCapacity: Double? {
    guard case let .batteryOriginalCapacity(v)? = responses[.batteryOriginalCapacity]?.response else { return nil }
    return v
  }

  public var batteryCurrentCapacity: Double? {
    guard case let .batteryCurrentCapacity(v)? = responses[.batteryCurrentCapacity]?.response else { return nil }
    return v
  }

  public var couplerTemperature: Double? {
    guard case let .couplerTemperature(v)? = responses[.couplerTemperature]?.response else { return nil }
    return v
  }
  
  public var batteryVoltage: Double? {
    guard case let .batteryVoltage(v)? = responses[.batteryVoltage]?.response else { return nil }
    return v
  }

  public var batteryCurrent: Double? {
    guard case let .batteryCurrent(v)? = responses[.batteryCurrent]?.response else { return nil }
    return v
  }

  public var batteryPower: Double? {
    guard case let .batteryPower(v)? = responses[.batteryPower]?.response else { return nil }
    return v
  }

  public var batteryEnergy: Double? {
    guard case let .batteryEnergy(v)? = responses[.batteryEnergy]?.response else { return nil }
    return v
  }
}
