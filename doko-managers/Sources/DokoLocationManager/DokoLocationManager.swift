import OSLog
import Foundation
@preconcurrency import MapKit

import SQLiteData

import DokoLogging
import DokoSharing
import Locations

public final class DokoLocationManager: Sendable {
  let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: DokoLocationManager.self)
  )

  public static let shared = DokoLocationManager()

  private init() {}

 public func lookup(id: Location.ID) -> Location {
    @FetchAll var locations: [Location]
    guard
      let location = locations.first(where: { $0.id == id })
    else {
      return .unexpectedLocation
    }
    return location
  }

  public func updateLocation(id: Location.ID, latitude: Double, longitude: Double, elevation: Double, sharedLocation: Bool = true) -> Location.ID {
    @FetchAll var locations: [Location]
    @Shared(.appSettings) var appSettings
    if sharedLocation,
       let locationID = locations.contains(latitude: latitude, longitude: longitude, within: appSettings.duplicateLocationThreshold),
       locationID != id
    {
      DokoLogging.shared.postLoggingResponse(.location("reused location: \(locationID)"))
      @Dependency(\.defaultDatabase) var database
      withErrorReporting {
        try database.write { db in
          try Location.where { $0.id.eq(id) }.delete().execute(db)
        }
      }
      DokoLogging.shared.postLoggingResponse(.location("deleted location: \(id)"))
      return locationID
    }
    reverseGeocode(id: id, draft: Location.Draft(latitude: latitude, longitude: longitude, elevation: elevation), localSearch: false)
    return id
  }

  public func addLocation(latitude: Double, longitude: Double, elevation: Double, sharedLocation: Bool = true) -> Location.ID? {
    @FetchAll var locations: [Location]
    @Shared(.appSettings) var appSettings
    if sharedLocation, let locationID = locations.contains(latitude: latitude, longitude: longitude, within: appSettings.duplicateLocationThreshold) {
      DokoLogging.shared.postLoggingResponse(.location("reused location: \(locationID)"))
      return locationID
    }

    @Dependency(\.defaultDatabase) var database
    var locationID: Location.ID? = nil
    let draftLocation = Location.Draft(latitude: latitude, longitude: longitude, elevation: elevation)
    withErrorReporting {
      try database.write { db in
        let id = try Location.upsert { draftLocation }.returning(\.id).fetchOne(db)
        locationID = id
      }
    }

    if let locationID {
      DokoLogging.shared.postLoggingResponse(.location("added location: \(locationID)"))
      reverseGeocode(id: locationID, draft: draftLocation)
    } else {
      DokoLogging.shared.postLoggingResponse(.error("Failed to add location"))
    }
    return locationID
  }

  /// Geocodes a draft and returns an updated copy with address fields populated.
  /// Does not save to the database.
  public func geocode(_ draft: Location.Draft) async -> Location.Draft {
    var result = draft
    guard let request = MKReverseGeocodingRequest(location: CLLocation(latitude: draft.latitude, longitude: draft.longitude)) else {
      DokoLogging.shared.postLoggingResponse(.error("Expected honest MKReverseGeocodingRequest()"))
      return result
    }
    let mapItems: [MKMapItem]
    do {
      mapItems = try await request.mapItems
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("MKReverseGeocodingRequest failed: \(error.localizedDescription)"))
      return result
    }
    guard let mapItem = mapItems.first else {
      DokoLogging.shared.postLoggingResponse(.location("MKReverseGeocodingRequest: no items"))
      return result
    }
    if let addressRepresentations = mapItem.addressRepresentations {
      DokoLogging.shared.postLoggingResponse(.location("cityName: \(addressRepresentations.cityName ?? "")"))
      DokoLogging.shared.postLoggingResponse(.location("cityWithContext: \(addressRepresentations.cityWithContext ?? "")"))
      DokoLogging.shared.postLoggingResponse(.location("regionName: \(addressRepresentations.regionName ?? "")"))
      DokoLogging.shared.postLoggingResponse(.location("region: \(addressRepresentations.region?.identifier ?? "")"))
      result.region = addressRepresentations.region?.identifier
      result.city = addressRepresentations.cityName
      result.stateProv = addressRepresentations.cityWithContext(.short)
      if let city = result.city, let stateProv = result.stateProv {
        result.stateProv = stateProv.replacingOccurrences(of: "\(city), ", with: "")
      }
      if let address = mapItem.address {
        DokoLogging.shared.postLoggingResponse(.location("shortAddress: \(address.shortAddress ?? "")"))
        if let shortAddress = address.shortAddress, let city = result.city {
          result.street = shortAddress.replacingOccurrences(of: ", \(city)", with: "")
        }
      }
      DokoLogging.shared.postLoggingResponse(.location("reverseGeo(\(result.placeName))"))
    }
    return result
  }

  private func reverseGeocode(id: Location.ID, draft: Location.Draft, localSearch: Bool = true) {
    Task { [location = draft] in
      var updatedDraft = await geocode(location)

      if localSearch {
        @Shared(.appSettings) var appSettings
        let poiSearch = MKLocalSearch(
          request: MKLocalPointsOfInterestRequest(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            radius: appSettings.poiThreshold
          )
        )
        let response = try? await poiSearch.start()
        if let response, let mapItem = response.mapItems.first {
          updatedDraft.name = mapItem.name
          DokoLogging.shared.postLoggingResponse(.location("reverseGeo(\(updatedDraft.placeName))"))
        }
      }

      var updatedLocation = Location(id: id, latitude: location.latitude, longitude: location.longitude, elevation: location.elevation)
      updatedLocation.name = updatedDraft.name
      updatedLocation.street = updatedDraft.street
      updatedLocation.city = updatedDraft.city
      updatedLocation.stateProv = updatedDraft.stateProv
      updatedLocation.region = updatedDraft.region

      @Dependency(\.defaultDatabase) var database
      withErrorReporting {
        try database.write { db in
          try Location.upsert { updatedLocation }.fetchOne(db)
        }
      }
    }
  }
}

extension Array where Element == Location {
  func contains(latitude: Double, longitude: Double, within meters: Double) -> Location.ID? {
    let newLocation = CLLocation(latitude: latitude, longitude: longitude)
    for existingLocation in self {
      let existing = CLLocation(latitude: existingLocation.latitude, longitude: existingLocation.longitude)
      let distance = newLocation.distance(from: existing)
      if distance <= meters {
        return existingLocation.id
      }
    }
    return nil
  }
}
