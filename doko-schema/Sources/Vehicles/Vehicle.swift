import Foundation

import SQLiteData

public protocol VehicleProtocol: Sendable {
  var vin: String { get }
}

@Table("vehicle")
public struct Vehicle: Identifiable, Hashable, Codable, Sendable {
  @Column(primaryKey: true)
  public let id: String
  public var vin: String { id }
  public var name: String?
  
  public init(vin: String, name: String? = nil) {
    self.id = vin
    self.name = name
  }
}
extension Vehicle.Draft: Identifiable, Equatable {}
extension Vehicle: VehicleProtocol {}
extension Vehicle.Draft: VehicleProtocol {
  public var vin: String { self.id ?? "Unknown" }
}

public enum WorldManufacturerIdentifier: String, Equatable {
  case unknown = "WMI?"
  case FordTruckUsa = "1FT"
  case FordMotorMexico = "3FM"
  case VwGermany = "WVG"
  case vwUsa = "1V2"

  public var manufacturer: String {
    switch self {
    case .FordTruckUsa, .FordMotorMexico:
      return "Ford"
    case .VwGermany, .vwUsa:
      return "VW"
    default:
      return "Unknown"
    }
  }
}

public enum ModelIdentifier: String, Equatable {
  case unknown

  case tk1r = "TK1R"
  case tk1s = "TK1S"
  case tk2r = "TK2R"
  case tk3r = "TK3R"
  case tk3s = "TK3S"
  case tk4s = "TK4S"

  case vw1e = "VW1E"
  case vw1b = "VW1B"
  case sw3l = "6W3L"
  case vw3l = "VW3L"
  case vw5l = "VW5L"
  case vw7l = "VW7L"

  case fmpe = "5MPE"
  case fnpe = "5NPE"
  case vmpe = "VMPE"
  case vnpe = "VNPE"
  case dmpe = "DMPE"
  case dnpe = "DNPE"
  case gmpe = "GMPE"
  case gnpe = "GNPE"
  case tmpe = "TMPE"
  case tnpe = "TNPE"
  case cmpe = "CMPE"
  case cnpe = "CNPE"

  public var description: String {
    switch self {
    case .tk1r, .tk1s:
      return "Mustang Mach-E Select"
    case .tk2r:
      return "Mustang Mach-E Cal RT1"
    case .tk3r, .tk3s:
      return "Mustang Mach-E Premium"
    case .tk4s:
      return "Mustang Mach-E GT"

    case .vw1e:
      return "F-150 Lightning"
    case .vw1b:
      return "F-150 Lightning Pro"
    case .vw3l:
      return "F-150 Lightning XLT"
    case .sw3l:
      return "F-150 Lightning Flash"
    case .vw5l:
      return "F-150 Lightning Lariat"
    case .vw7l:
      return "F-150 Lightning Platinum"

    case .fmpe, .fnpe:
      return "ID.4 S"
    case .vmpe, .vnpe, .cmpe, .cnpe, .dmpe, .dnpe:
      return "ID.4 Pro"
    case .gmpe, .gnpe, .tmpe, .tnpe:
      return "ID.4 Pro S"

    case .unknown:
      return "Unknown"
    }
  }
}

extension VehicleProtocol {
  public var modelIdentifier: ModelIdentifier {
    let start = vin.index(vin.startIndex, offsetBy: 3)
    let end = vin.index(vin.startIndex, offsetBy: 7)
    let modelIdentifierString = String(vin[start..<end])
    let modelIdentifier = ModelIdentifier(rawValue: modelIdentifierString) ?? .unknown
    return modelIdentifier
  }
  
  public var year: String {
    let start = vin.index(vin.startIndex, offsetBy: 9)
    let end = vin.index(vin.startIndex, offsetBy: 10)
    let modelYearString = String(vin[start..<end])
    let modelYears: [String: Int] = ["M": 2021, "N": 2022, "P": 2023, "R": 2024, "S": 2025, "T": 2026, "U": 2027, "V": 2028, "W": 2029]
    let year = modelYears[modelYearString] ?? -1
    return year.description
  }
  
  public var make: String {
    let start = vin.index(vin.startIndex, offsetBy: 0)
    let end = vin.index(vin.startIndex, offsetBy: 3)
    let wmiString = String(vin[start..<end])
    let wmi = WorldManufacturerIdentifier(rawValue: wmiString) ?? .unknown
    return "\(wmi.manufacturer)"
  }
  
  public var model: String {
    return "\(modelIdentifier.description)"
  }
  public var makeModel: String { self.make + " " + self.model }
  public var yearModel: String { self.year + " " + self.model }
  public var yearMakeModel: String { self.year + " " + self.make + " " + self.model }
  
  public var truck: Bool {
    let start = vin.index(vin.startIndex, offsetBy: 0)
    let end = vin.index(vin.startIndex, offsetBy: 3)
    let wmiString = String(vin[start..<end])
    let wmi = WorldManufacturerIdentifier(rawValue: wmiString) ?? .unknown
    return wmi == .FordTruckUsa
  }
}
