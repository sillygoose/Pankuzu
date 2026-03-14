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
    @Shared(.duplicateLocationThreshold) var duplicateLocationThreshold
    if sharedLocation,
       let locationID = locations.contains(latitude: latitude, longitude: longitude, within: duplicateLocationThreshold),
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
    @Shared(.duplicateLocationThreshold) var duplicateLocationThreshold
    if sharedLocation, let locationID = locations.contains(latitude: latitude, longitude: longitude, within: duplicateLocationThreshold) {
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

  private func reverseGeocode(id: Location.ID, draft: Location.Draft, localSearch: Bool = true) {
    @Dependency(\.defaultDatabase) var database
    Task { [location = draft] in
      guard let request = MKReverseGeocodingRequest(location: CLLocation(latitude: location.latitude, longitude: location.longitude)) else {
        DokoLogging.shared.postLoggingResponse(.error("Expected honest MKReverseGeocodingRequest()"))
        return
      }
      let mapItems: [MKMapItem]
      do {
        mapItems = try await request.mapItems
      } catch {
        DokoLogging.shared.postLoggingResponse(.error("MKReverseGeocodingRequest failed: \(error.localizedDescription)"))
        return
      }

      if let mapItem = mapItems.first {
        @Shared(.poiThreshold) var poiThreshold
        var updatedLocation = Location(id: id, latitude: location.latitude, longitude: location.longitude, elevation: location.elevation)
        if let addressRepresentations = mapItem.addressRepresentations {
          updatedLocation.region = addressRepresentations.region?.identifier
          updatedLocation.city = addressRepresentations.cityName
          updatedLocation.stateProv = addressRepresentations.cityWithContext(.short)
          if let city = updatedLocation.city, let stateProv = updatedLocation.stateProv {
            let trimmedStateProv = stateProv.replacingOccurrences(of: "\(city), ", with: "")
            updatedLocation.stateProv = trimmedStateProv
          }
          if let address = mapItem.address {
            if let shortAddress = address.shortAddress, let city = updatedLocation.city {
              let trimmedStreet = shortAddress.replacingOccurrences(of: ", \(city)", with: "")
              updatedLocation.street = trimmedStreet
            }
          }
          DokoLogging.shared.postLoggingResponse(.location("reverseGeo(\(updatedLocation.placeName))"))
        }
        if localSearch {
          let poiSearch = MKLocalSearch(
            request: MKLocalPointsOfInterestRequest(
              center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
              radius: poiThreshold
            )
          )
          let response = try? await poiSearch.start()
          if let response, let mapItem = response.mapItems.first {
            updatedLocation.name = mapItem.name
            DokoLogging.shared.postLoggingResponse(.location("reverseGeo(\(updatedLocation.placeName))"))
          }
        }
        withErrorReporting {
          try database.write { db in
            try Location.upsert { updatedLocation }.fetchOne(db)
          }
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
