import Foundation

import SQLiteData

import Vehicles
import Locations
import DokoSchemaTypes

@Table("charge")
public struct Charge: Equatable, Hashable, Identifiable, Codable, Sendable {
  public let id: UUID
  public var deleted: Date?

  public var vehicleID: Vehicle.ID
  public var locationID: Location.ID

  public var latitude: Double
  public var longitude: Double
  public var elevation: Double

  public var timeStart: Date
  public var timeEnd: Date
  public var duration: TimeInterval

  public var chargerType: ChargerType
  public var odometer: Double

  public var energyToEmptyStart: Double?
  public var energyToEmptyEnd: Double?
  public var energy: Double?

  public var distanceToEmptyStart: Double?
  public var distanceToEmptyEnd: Double?
  public var range: Double?

  public var stateOfChargeStart: Double?
  public var stateOfChargeEnd: Double?

  public var batteryStateOfHealth: Double?
  public var batteryTempStart: Double?
  public var batteryTempEnd: Double?
  
  public var couplerTempStart: Double?
  public var couplerTempEnd: Double?

  public var weatherTempStart: Double?
  public var weatherConditionsStart: String?

  public init(
    id: UUID,
    deleted: Date? = nil,
    vehicleID: Vehicle.ID,
    locationID: Location.ID,
    latitude: Double,
    longitude: Double,
    elevation: Double,
    timeStart: Date,
    timeEnd: Date,
    chargerType: ChargerType,
    odometer: Double,
    energyToEmptyStart: Double? = nil,
    energyToEmptyEnd: Double? = nil,
    energy: Double? = nil,
    distanceToEmptyStart: Double? = nil,
    distanceToEmptyEnd: Double? = nil,
    range: Double? = nil,
    stateOfChargeStart: Double? = nil,
    stateOfChargeEnd: Double? = nil,
    batteryStateOfHealth: Double? = nil,
    batteryTempStart: Double? = nil,
    batteryTempEnd: Double? = nil,
    couplerTempStart: Double? = nil,
    couplerTempEnd: Double? = nil,
    weatherTempStart: Double? = nil,
    weatherConditionsStart: String? = nil,
  ) {
    self.id = id
    self.deleted = deleted
    self.vehicleID = vehicleID
    self.locationID = locationID
    self.latitude = latitude
    self.longitude = longitude
    self.elevation = elevation
    self.timeStart = timeStart
    self.timeEnd = timeEnd
    self.duration = timeEnd.timeIntervalSince(timeStart)
    self.chargerType = chargerType
    self.odometer = odometer
    self.energyToEmptyStart = energyToEmptyStart
    self.energyToEmptyEnd = energyToEmptyEnd
    self.energy = energy
    self.distanceToEmptyStart = distanceToEmptyStart
    self.distanceToEmptyEnd = distanceToEmptyEnd
    self.range = range
    self.stateOfChargeStart = stateOfChargeStart
    self.stateOfChargeEnd = stateOfChargeEnd
    self.distanceToEmptyStart = distanceToEmptyStart
    self.distanceToEmptyEnd = distanceToEmptyEnd
    self.batteryStateOfHealth = batteryStateOfHealth
    self.batteryTempStart = batteryTempStart
    self.batteryTempEnd = batteryTempEnd
    self.couplerTempStart = couplerTempStart
    self.couplerTempEnd = couplerTempEnd
    self.weatherTempStart = weatherTempStart
    self.weatherConditionsStart = weatherConditionsStart
  }

  public enum ChargerType: Int, Identifiable, Codable, Sendable, CaseIterable, QueryBindable {
    case none = 0, ac, dc
    public var id: Int { rawValue }
    public var description: String {
      switch self {
      case .ac: return "AC"
      case .dc: return "DCFC"
      case .none: return "None"
      }
    }
  }

  public static let honestEmptyCharge: Charge = .init(
    id: UUID(0),
    vehicleID: "unknown",
    locationID: UUID(0),
    latitude: 0, longitude: 0, elevation: 0,
    timeStart: Date.distantPast, timeEnd: Date.distantPast,
    chargerType: .none,
    odometer: 0
  )
}
extension Charge.Draft: Identifiable, Sendable {}

extension Charge.TableColumns {
  public var isAcCharge: some QueryExpression<Bool> { return chargerType.eq(Charge.ChargerType.ac) }
  public var isDcCharge: some QueryExpression<Bool> { return chargerType.eq(Charge.ChargerType.dc) }
  public var isNoCharge: some QueryExpression<Bool> { return chargerType.eq(Charge.ChargerType.none) }
  public var isDeleted: some QueryExpression<Bool> {  return deleted.isNot(nil)  }
  public var deletedOrdering: some QueryExpression { return deleted.desc()  }
  public func readyForDeletion(days: Int = 30) -> some QueryExpression<Bool> {
    @Dependency(\.date.now) var now
    let shouldDelete = Calendar.current.date(byAdding: .day, value: -days, to: now)!
    return #sql("coalesce(date(\(deleted)) > date(\(shouldDelete)), 0)")
  }
}

@Table("chargeHistory")
public struct ChargeHistory: Hashable, Identifiable, Codable, Sendable {
  @Column(primaryKey: true)
  public let chargeID: Charge.ID
  public var id: Charge.ID { chargeID }

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var batteryPower: [DokoDataPoint]

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var stateOfCharge: [DokoDataPoint]

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var batteryEnergy: [DokoDataPoint]

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var energyToEmpty: [DokoDataPoint]

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var batteryTemp: [DokoDataPoint]

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var couplerTemp: [DokoDataPoint]

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var distanceToEmpty: [DokoDataPoint]

  public init(
    chargeID: Charge.ID,
    batteryPower: [DokoDataPoint] = [],
    stateOfCharge: [DokoDataPoint] = [],
    batteryEnergy: [DokoDataPoint] = [],
    energyToEmpty: [DokoDataPoint] = [],
    batteryTemp: [DokoDataPoint] = [],
    couplerTemp: [DokoDataPoint] = [],
    distanceToEmpty: [DokoDataPoint] = []
  ) {
    self.chargeID = chargeID
    self.batteryPower = batteryPower
    self.stateOfCharge = stateOfCharge
    self.batteryEnergy = batteryEnergy
    self.energyToEmpty = energyToEmpty
    self.batteryTemp = batteryTemp
    self.couplerTemp = couplerTemp
    self.distanceToEmpty = distanceToEmpty
  }

  private enum CodingKeys: String, CodingKey {
    case chargeID = "cid"
    case batteryPower = "bp"
    case stateOfCharge = "soc"
    case batteryEnergy = "be"
    case energyToEmpty = "ete"
    case batteryTemp = "bt"
    case couplerTemp = "ct"
    case distanceToEmpty = "dte"
  }

  private enum LegacyCodingKeys: String, CodingKey {
    case chargeID, batteryPower, stateOfCharge, batteryEnergy, energyToEmpty, batteryTemp, couplerTemp, distanceToEmpty
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.chargeID) {
      chargeID = try container.decode(Charge.ID.self, forKey: .chargeID)
      batteryPower = try container.decodeIfPresent([DokoDataPoint].self, forKey: .batteryPower) ?? []
      stateOfCharge = try container.decodeIfPresent([DokoDataPoint].self, forKey: .stateOfCharge) ?? []
      batteryEnergy = try container.decodeIfPresent([DokoDataPoint].self, forKey: .batteryEnergy) ?? []
      energyToEmpty = try container.decodeIfPresent([DokoDataPoint].self, forKey: .energyToEmpty) ?? []
      batteryTemp = try container.decodeIfPresent([DokoDataPoint].self, forKey: .batteryTemp) ?? []
      couplerTemp = try container.decodeIfPresent([DokoDataPoint].self, forKey: .couplerTemp) ?? []
      distanceToEmpty = try container.decodeIfPresent([DokoDataPoint].self, forKey: .distanceToEmpty) ?? []
    } else {
      let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
      chargeID = try legacy.decode(Charge.ID.self, forKey: .chargeID)
      batteryPower = try legacy.decodeIfPresent([DokoDataPoint].self, forKey: .batteryPower) ?? []
      stateOfCharge = try legacy.decodeIfPresent([DokoDataPoint].self, forKey: .stateOfCharge) ?? []
      batteryEnergy = try legacy.decodeIfPresent([DokoDataPoint].self, forKey: .batteryEnergy) ?? []
      energyToEmpty = try legacy.decodeIfPresent([DokoDataPoint].self, forKey: .energyToEmpty) ?? []
      batteryTemp = try legacy.decodeIfPresent([DokoDataPoint].self, forKey: .batteryTemp) ?? []
      couplerTemp = try legacy.decodeIfPresent([DokoDataPoint].self, forKey: .couplerTemp) ?? []
      distanceToEmpty = try legacy.decodeIfPresent([DokoDataPoint].self, forKey: .distanceToEmpty) ?? []
    }
  }

  public func encode(to encoder: Encoder) throws {
    if (encoder.userInfo[.useLegacyKeys] as? Bool) == true {
      var container = encoder.container(keyedBy: LegacyCodingKeys.self)
      try container.encode(chargeID, forKey: .chargeID)
      try container.encode(batteryPower, forKey: .batteryPower)
      try container.encode(stateOfCharge, forKey: .stateOfCharge)
      try container.encode(batteryEnergy, forKey: .batteryEnergy)
      try container.encode(energyToEmpty, forKey: .energyToEmpty)
      try container.encode(batteryTemp, forKey: .batteryTemp)
      try container.encode(couplerTemp, forKey: .couplerTemp)
      try container.encode(distanceToEmpty, forKey: .distanceToEmpty)
    } else {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(chargeID, forKey: .chargeID)
      try container.encode(batteryPower, forKey: .batteryPower)
      try container.encode(stateOfCharge, forKey: .stateOfCharge)
      try container.encode(batteryEnergy, forKey: .batteryEnergy)
      try container.encode(energyToEmpty, forKey: .energyToEmpty)
      try container.encode(batteryTemp, forKey: .batteryTemp)
      try container.encode(couplerTemp, forKey: .couplerTemp)
      try container.encode(distanceToEmpty, forKey: .distanceToEmpty)
    }
  }
}
