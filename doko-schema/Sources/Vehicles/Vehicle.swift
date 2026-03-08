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

  public init(decoding vin: String, name: String? = nil) {
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

public enum VehicleType: CaseIterable, Sendable {
  case undetermined
  case fordElectric
  case fordMachE
  case vwElectric

  public var description: String {
    switch self {
    case .undetermined: return "Undetermined"
    case .fordElectric: return "Ford Electric"
    case .fordMachE: return "Ford Mustang Mach-E"
    case .vwElectric: return "VW Electric"
    }
  }
}

extension VehicleProtocol {
  public var year: String {
    guard vin.count == 17 else { return "Unknown" }
    let modelYearString = String(vin[vin.index(vin.startIndex, offsetBy: 9)])
    let modelYears: [String: Int] = ["M": 2021, "N": 2022, "P": 2023, "R": 2024, "S": 2025, "T": 2026, "U": 2027, "V": 2028, "W": 2029]
    let year = modelYears[modelYearString] ?? -1
    return year.description
  }

  public var make: String {
    let wmi = WorldManufacturerIdentifier(rawValue: String(vin.prefix(3))) ?? .unknown
    return wmi.manufacturer
  }

  public var model: String {
    guard vin.count == 17 else { return "Unknown" }
    let wmi = String(vin.prefix(3))
    let pos5 = vin[vin.index(vin.startIndex, offsetBy: 4)]
    let pos6 = vin[vin.index(vin.startIndex, offsetBy: 5)]
    let pos7 = vin[vin.index(vin.startIndex, offsetBy: 6)]
    switch wmi {
    case "3FM":
      let trim: String
      switch String([pos5, pos6, pos7]) {
      case "K1R", "K1S": trim = "Select"
      case "K2R":        trim = "Cal Route 1"
      case "K3R", "K3S": trim = "Premium"
      case "K4S":        trim = "GT"
      default:           trim = ""
      }
      return trim.isEmpty ? "Mustang Mach-E" : "Mustang Mach-E \(trim)"
    case "1FT":
      switch String([pos5, pos6, pos7]) {
      case "W1E": return "F-150 Lightning"
      case "W1L": return "F-150 Lightning Pro"
      case "W3L": return "F-150 Lightning XLT"
      case "W5L": return "F-150 Lightning Lariat"
      case "W7L": return "F-150 Lightning Platinum"
      default:    return "F-150 Lightning"
      }
    case "WVG", "1V2":
      return "ID.4"
    default:
      return "Unknown"
    }
  }

  public var makeModel: String { make + " " + model }
  public var yearModel: String { year + " " + model }
  public var yearMakeModel: String { year + " " + make + " " + model }

  public var truck: Bool {
    let wmi = WorldManufacturerIdentifier(rawValue: String(vin.prefix(3))) ?? .unknown
    return wmi == .FordTruckUsa
  }

  public var vehicleType: VehicleType {
    guard vin.count == 17 else { return .undetermined }
    let wmi = String(vin.prefix(3))
    let pos4 = vin[vin.index(vin.startIndex, offsetBy: 3)]
    let pos8 = vin[vin.index(vin.startIndex, offsetBy: 7)]
    switch wmi {
    case "3FM":
      guard "M7SUXE".contains(pos8) else { return .undetermined }
      let modelYearChar = String(vin[vin.index(vin.startIndex, offsetBy: 9)])
      let modelYears: [String: Int] = ["M": 2021, "N": 2022, "P": 2023, "R": 2024, "S": 2025, "T": 2026, "U": 2027, "V": 2028, "W": 2029]
      let modelYear = modelYears[modelYearChar] ?? 0
      return modelYear >= 2025 ? .fordMachE : .fordElectric
    case "1FT":
      let validGVWR = pos4 == "V" || pos4 == "6"
      let validEngine = "SK7MLV".contains(pos8)
      return validGVWR && validEngine ? .fordElectric : .undetermined
    case "WVG", "1V2":
      return .vwElectric
    default:
      return .undetermined
    }
  }
}
