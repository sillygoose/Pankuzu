import Foundation
import CoreLocation

import SQLiteData

public protocol LocationProtocol: Sendable {
  var latitude: Double { get }
  var longitude: Double { get }
  var elevation: Double { get }
}

@Table("location")
public struct Location: Identifiable, Hashable, Codable, Sendable {
  public let id: UUID
  public var deleted: Date?
  public var latitude: Double
  public var longitude: Double
  public var elevation: Double
  public var name: String?
  public var street: String?
  public var city: String?
  public var stateProv: String?
  public var region: String?
  
  public init(
    id: UUID,
    hidden: Bool? = nil,
    latitude: Double,
    longitude: Double,
    elevation: Double,
    name: String? = nil,
    street: String? = nil,
    city: String? = nil,
    stateProv: String? = nil,
    region: String? = nil,
  ) {
    self.id = id
    self.latitude = latitude
    self.longitude = longitude
    self.elevation = elevation
    self.name = name
    self.street = street
    self.city = city
    self.stateProv = stateProv
    self.region = region
  }
}
extension Location.Draft: Identifiable, Equatable {}
extension Location: LocationProtocol {}
extension Location.Draft: LocationProtocol {}

extension LocationProtocol {
  public var coordinate: CLLocationCoordinate2D {  CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}

extension Location.TableColumns {
  public var isDeleted: some QueryExpression<Bool> { deleted.isNot(nil) }
  public var deletedOrdering: some QueryExpression { deleted.desc() }
}

extension Location {
  public static var unexpectedLocation: Location {
    Location(id: UUID(0), latitude: -1, longitude: -1, elevation: -1, name: "<Location Error>")
  }

  public var placeName: String {
    if let name { return name }
    if let street { return street }
    return String(format: "(%.5f, %.5f)", latitude, longitude)
  }

  public var streetName: String {
    guard let street = street else { return "???" }
    return street
  }

  public var cityState: String {
    return [city, stateProv]
      .compactMap({ $0 })
      .joined(separator: ", ")
  }

  public var placeNameCityState: String {
    if let name {
      return [name, city, stateProv]
        .compactMap({ $0 })
        .joined(separator: ", ")
    }
    if street == nil, city == nil, stateProv == nil {
      return String(format: "(%.5f, %.5f)", latitude, longitude)
    }
    return [street, city, stateProv]
      .compactMap({ $0 })
      .joined(separator: ", ")
  }
}
