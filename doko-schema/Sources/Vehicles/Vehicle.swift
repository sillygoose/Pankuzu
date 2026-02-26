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
  case miUNKNOWN

  case miTK1R = "TK1R"    // Mustang-Mach-E
  case miTK1S = "TK1S"
  case miTK2R = "TK2R"
  case miTK3R = "TK3R"
  case miTK3S = "TK3S"
  case miTK4S = "TK4S"

  case mi6W1E = "6W1E"    // F-150 Lightning
  case mi6W3L = "6W3L"
  case mi6W5L = "6W5L"
  case miVW1E = "VW1E"
  case miVW1B = "VW1B"
  case miVW3L = "VW3L"
  case miVW5L = "VW5L"
  case miVW7L = "VW7L"

  case mi5MPE = "5MPE"    // VW ID.4
  case mi5NPE = "5NPE"
  case miVMPE = "VMPE"
  case miVNPE = "VNPE"
  case miDMPE = "DMPE"
  case miDNPE = "DNPE"
  case miGMPE = "GMPE"
  case miGNPE = "GNPE"
  case miTMPE = "TMPE"
  case miTNPE = "TNPE"
  case miCMPE = "CMPE"
  case miCNPE = "CNPE"
  case miJSPE = "JSPE"

  public var description: String {
    switch self {
    case .miTK1R, .miTK1S:
      return "Mustang Mach-E Select"
    case .miTK2R:
      return "Mustang Mach-E Cal RT1"
    case .miTK3R, .miTK3S:
      return "Mustang Mach-E Premium"
    case .miTK4S:
      return "Mustang Mach-E GT"

    case .miVW1E:
      return "F-150 Lightning"
    case .miVW1B:
      return "F-150 Lightning Pro"
    case .miVW3L:
      return "F-150 Lightning XLT"
    case .mi6W3L:
      return "F-150 Lightning Flash"
    case .mi6W1E, .miVW5L, .mi6W5L:
      return "F-150 Lightning Lariat"
    case .miVW7L:
      return "F-150 Lightning Platinum"

    case .mi5MPE, .mi5NPE:
      return "ID.4 S"
    case .miVMPE, .miVNPE, .miCMPE, .miCNPE, .miDMPE, .miDNPE:
      return "ID.4 Pro"
    case .miGMPE, .miGNPE, .miTMPE, .miTNPE, .miJSPE:
      return "ID.4 Pro S"

    case .miUNKNOWN:
      return "Unknown"
    }
  }
}

extension VehicleProtocol {
  public var modelIdentifier: ModelIdentifier {
    let start = vin.index(vin.startIndex, offsetBy: 3)
    let end = vin.index(vin.startIndex, offsetBy: 7)
    let modelIdentifierString = String(vin[start..<end])
    let modelIdentifier = ModelIdentifier(rawValue: modelIdentifierString) ?? .miUNKNOWN
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
