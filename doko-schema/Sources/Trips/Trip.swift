import Foundation

import SQLiteData

import Vehicles
import Locations
import DokoSchemaTypes
import DokoLogging

@Table("trip")
public struct Trip: Equatable, Identifiable, Hashable, Codable, Sendable {
  public let id: UUID
  public var deleted: Date?

  public var vehicleID: Vehicle.ID
  public var originID: Location.ID
  public var destinationID: Location.ID

  public var latitudeStart: Double
  public var longitudeStart: Double
  public var elevationStart: Double

  public var latitudeEnd: Double
  public var longitudeEnd: Double
  public var elevationEnd: Double

  public var timeStart: Date
  public var timeEnd: Date
  public var duration: TimeInterval

  public var odometerStart: Double
  public var odometerEnd: Double
  public var distance: Double

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

  public var weatherTempStart: Double?
  public var weatherTempEnd: Double?
  public var weatherTempMeanWeighted: Double?

  public var weatherConditionsStart: String?
  public var weatherConditionsEnd: String?

  public init(
    id: UUID,
    deleted: Date? = nil,
    vehicleID: Vehicle.ID,
    originID: Location.ID,
    destinationID: Location.ID,
    latitudeStart: Double,
    longitudeStart: Double,
    elevationStart: Double,
    latitudeEnd: Double,
    longitudeEnd: Double,
    elevationEnd: Double,
    timeStart: Date,
    timeEnd: Date,
    odometerStart: Double,
    odometerEnd: Double,
    energy: Double? = nil,
    energyToEmptyStart: Double? = nil,
    energyToEmptyEnd: Double? = nil,
    range: Double? = nil,
    distanceToEmptyStart: Double? = nil,
    distanceToEmptyEnd: Double? = nil,
    stateOfChargeStart: Double? = nil,
    stateOfChargeEnd: Double? = nil,
    batteryStateOfHealth: Double? = nil,
    batteryTempStart: Double? = nil,
    batteryTempEnd: Double? = nil,
    weatherTempStart: Double? = nil,
    weatherTempEnd: Double? = nil,
    weatherTempMeanWeighted: Double? = nil,
    weatherConditionsStart: String? = nil,
    weatherConditionsEnd: String? = nil,
  ) {
    self.id = id
    self.deleted = deleted
    self.vehicleID = vehicleID
    self.originID = originID
    self.destinationID = destinationID
    self.latitudeStart = latitudeStart
    self.longitudeStart = longitudeStart
    self.elevationStart = elevationStart
    self.latitudeEnd = latitudeEnd
    self.longitudeEnd = longitudeEnd
    self.elevationEnd = elevationEnd
    self.timeStart = timeStart
    self.timeEnd = timeEnd
    self.duration = timeEnd.timeIntervalSince(timeStart)

    self.odometerStart = odometerStart
    self.odometerEnd = odometerEnd
    self.distance = odometerEnd - odometerStart

    self.energyToEmptyStart = energyToEmptyStart
    self.energyToEmptyEnd = energyToEmptyEnd
    self.energy = energy

    self.distanceToEmptyStart = distanceToEmptyStart
    self.distanceToEmptyEnd = distanceToEmptyEnd
    self.range = range

    self.stateOfChargeStart = stateOfChargeStart
    self.stateOfChargeEnd = stateOfChargeEnd
    
    self.batteryStateOfHealth = batteryStateOfHealth
    self.batteryTempStart = batteryTempStart
    self.batteryTempEnd = batteryTempEnd
    self.weatherTempStart = weatherTempStart
    self.weatherTempEnd = weatherTempEnd
    self.weatherTempMeanWeighted = weatherTempMeanWeighted
    self.weatherConditionsStart = weatherConditionsStart
    self.weatherConditionsEnd = weatherConditionsEnd
  }

  public static let honestEmptyTrip: Trip = .init(
    id: UUID(0),
    vehicleID: "unknown",
    originID: UUID(0), destinationID: UUID(0),
    latitudeStart: 0, longitudeStart: 0, elevationStart: 0, latitudeEnd: 0, longitudeEnd: 0, elevationEnd: 0,
    timeStart: Date.distantPast, timeEnd: Date.distantPast,
    odometerStart: 0, odometerEnd: 0
  )
}
extension Trip.Draft: Identifiable, Sendable {}

extension Trip.TableColumns {
  public var isDeleted: some QueryExpression<Bool> { return deleted.isNot(nil) }
  public var deletedOrdering: some QueryExpression { return deleted.desc() }
  public func readyForDeletion(days: Int = 30) -> some QueryExpression<Bool> {
    @Dependency(\.date.now) var now
    let shouldDelete = Calendar.current.date(byAdding: .day, value: -days, to: now)!
    return #sql("coalesce(date(\(deleted)) > date(\(shouldDelete)), 0)")
  }
}

@Table("tripPosition")
public struct TripPosition: Hashable, Identifiable, Codable, Sendable {
  @Column(primaryKey: true)
  public let tripID: Trip.ID
  public var id: Trip.ID { tripID }

  @Column(as: [VehiclePosition].JSONRepresentation.self)
  public var path: [VehiclePosition]
  
  public init(
    tripID: Trip.ID,
    path: [VehiclePosition] = []
  ) {
    self.tripID = tripID
    self.path = path
  }
}

@Table("tripElevation")
public struct TripElevation: Hashable, Identifiable, Codable, Sendable {
  @Column(primaryKey: true)
  public let tripID: Trip.ID
  public var id: Trip.ID { tripID }

  @Column(as: [VehicleElevation].JSONRepresentation.self)
  public var elevations: [VehicleElevation]

  public init(
    tripID: Trip.ID,
    elevations: [VehicleElevation] = []
  ) {
    self.tripID = tripID
    self.elevations = elevations
  }
}

@Table("tripData")
public struct TripData: Hashable, Identifiable, Codable, Sendable {
  @Column(primaryKey: true)
  public let tripID: Trip.ID
  public var id: Trip.ID { tripID }

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var odometer: [DokoDataPoint]

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var stateOfCharge: [DokoDataPoint]

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var batteryEnergy: [DokoDataPoint]

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var energyToEmpty: [DokoDataPoint]

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var distanceToEmpty: [DokoDataPoint]

  @Column(as: [DokoDataPoint].JSONRepresentation.self)
  public var batteryTemp: [DokoDataPoint]

  public init(
    tripID: Trip.ID,
    odometer: [DokoDataPoint] = [],
    stateOfCharge: [DokoDataPoint] = [],
    batteryEnergy: [DokoDataPoint] = [],
    energyToEmpty: [DokoDataPoint] = [],
    distanceToEmpty: [DokoDataPoint] = [],
    batteryTemp: [DokoDataPoint] = []
  ) {
    self.tripID = tripID
    self.odometer = odometer
    self.stateOfCharge = stateOfCharge
    self.batteryEnergy = batteryEnergy
    self.energyToEmpty = energyToEmpty
    self.distanceToEmpty = distanceToEmpty
    self.batteryTemp = batteryTemp
  }
  
//  public init(from decoder: Decoder) throws {
//    let container = try decoder.container(keyedBy: CodingKeys.self)
//    tripID = try container.decode(Trip.ID.self, forKey: .tripID)
//    odometer = try container.decodeIfPresent([DokoDataPoint].self, forKey: .odometer) ?? []
//    stateOfCharge = try container.decodeIfPresent([DokoDataPoint].self, forKey: .stateOfCharge) ?? []
//    batteryEnergy = try container.decodeIfPresent([DokoDataPoint].self, forKey: .batteryEnergy) ?? []
//    energyToEmpty = try container.decodeIfPresent([DokoDataPoint].self, forKey: .energyToEmpty) ?? []
//    distanceToEmpty = try container.decodeIfPresent([DokoDataPoint].self, forKey: .distanceToEmpty) ?? []
//    batteryTemp = try container.decodeIfPresent([DokoDataPoint].self, forKey: .batteryTemp) ?? []
//  }
}

@Table("tripWeather")
public struct TripWeather: Hashable, Identifiable, Codable, Sendable {
  @Column(primaryKey: true)
  public let tripID: Trip.ID
  public var id: Trip.ID { tripID }

  @Column(as: [DokoWeather].JSONRepresentation.self)
  public var weather: [DokoWeather]

  public init(
    tripID: Trip.ID,
    weather: [DokoWeather] = []
  ) {
    self.tripID = tripID
    self.weather = weather
  }
}
