import CoreLocation
import OSLog

import DokoTypes
import DokoPacketManager
import DokoLogging
import DokoSharing

// MARK: - Location Filter Protocol

protocol LocationFilter: Actor {
  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool
}

// MARK: - Location Filtering

extension CoreLocationManager {
  func filterLocation(_ location: CLLocation) async {
    let tripPositionChange = await filterTripPositionChange(location)
    let tripElevationChange = await filterTripElevationChange(location)
    let tripCourseChange = await filterTripCourseChange(location)
    let tripSpeedChange = await filterTripSpeedChange(location)
    
    if tripPositionChange || tripElevationChange || tripCourseChange || tripSpeedChange {
      var dokoResponses: DokoResponseDictionary = [:]
      dokoResponses[.position] = DokoCommandResponse(command: .tripPosition, response: .position(DokoPosition(position: location)))
      let dokoResponsePacket = DokoResponsePacket(type: .tripCoreElevation, responses: dokoResponses)
      await DokoPacketManager.shared.appendDokoResponsePacket(dokoResponsePacket)
    }
  }

  func resetLocationFilters() async {
    lastOutputLocation = nil
  }
}

// MARK: - Accuracy Filter

actor AccuracyFilter: LocationFilter {
  let horizontalAccuracyThreshold: Double = 40
  let verticalAccuracyThreshold: Double = 50

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard location.horizontalAccuracy >= 0 && location.verticalAccuracy >= 0 else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("AccuracyFilter.invalid"))
      return false
    }
    guard location.horizontalAccuracy < horizontalAccuracyThreshold else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("AccuracyFilter.horizontalAccuracy(\(String(format: "%.0f", location.horizontalAccuracy))"))
      return false
    }
    guard location.verticalAccuracy < verticalAccuracyThreshold else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("AccuracyFilter.verticalAccuracy(\(String(format: "%.0f", location.verticalAccuracy))"))
      return false
    }
    return true
  }
}

extension CoreLocationManager {
  static let accuracyFilter = AccuracyFilter()

  func filterAccuracy(_ location: CLLocation) async -> CLLocation? {
    guard await Self.accuracyFilter.shouldAccept(location, lastOutputLocation) else { return nil }
    return location
  }
}

// MARK: - Trip Position Change Filters

actor TripPositionChangeFilter: LocationFilter {
  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard let last = previousLocation else { return true }
    if location.timestamp == last.timestamp {
      DokoLogging.shared.postLoggingResponse(.coreLocation("TripPositionChangeFilter.timestamp"))
      return false
    }

    let distance = location.distance(from: last)
    if distance < appSettings.identicalTripPositionDistance {
      DokoLogging.shared.postLoggingResponse(.coreLocation("TripPositionChangeFilter.distance"))
      return false
    }
    return true
  }
}

extension CoreLocationManager {
  static let tripPositionChangeFilter = TripPositionChangeFilter()

  func filterTripPositionChange(_ location: CLLocation) async -> Bool {
    guard await Self.tripPositionChangeFilter.shouldAccept(location, lastOutputLocation) else { return false }
    return true
  }
}

// MARK: - Trip Elevation Charge Filter

actor TripElevationChangeFilter: LocationFilter {
  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard let last = previousLocation else { return true }
    if location.timestamp == last.timestamp {
      DokoLogging.shared.postLoggingResponse(.coreLocation("TripElevationChangeFilter.timestamp"))
      return false
    }

    let distance = location.distance(from: last)
    if distance > appSettings.maximumTripElevationDistance { return true }

    if abs(last.altitude - location.altitude) < appSettings.minimumTripElevationChange {
      DokoLogging.shared.postLoggingResponse(.coreLocation("TripElevationChangeFilter.change"))
      return false
    }
    return true
  }
}

extension CoreLocationManager {
  static let tripElevationChangeFilter = TripElevationChangeFilter()

  func filterTripElevationChange(_ location: CLLocation) async -> Bool {
    guard await Self.tripElevationChangeFilter.shouldAccept(location, lastOutputLocation) else { return false }
    return true
  }
}

// MARK: - Trip Course Change Filter

actor TripCourseChangeFilter: LocationFilter {
  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard location.course >= 0, let previousLocation else { return false }
    guard abs(location.course - previousLocation.course) > appSettings.tripPositionCourseDeviation else { return false }
    DokoLogging.shared.postLoggingResponse(.coreLocation("TripCourseChangeFilter.course"))
    return true
  }
}

extension CoreLocationManager {
  static let tripCourseChangeFilter = TripCourseChangeFilter()

  func filterTripCourseChange(_ location: CLLocation) async -> Bool {
    guard await Self.tripCourseChangeFilter.shouldAccept(location, lastOutputLocation) else { return false }
    return true
  }
}

// MARK: - Trip Speed Change Filter

actor TripSpeedChangeFilter: LocationFilter {
  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard location.speed >= 0, let previousLocation else { return false }
    guard (abs(location.speed - previousLocation.speed) * 3.6) > appSettings.tripPositionSpeedDeviation else { return false } //###
    DokoLogging.shared.postLoggingResponse(.coreLocation("TripSpeedChangeFilter.speed"))
    return true
  }
}

extension CoreLocationManager {
  static let tripSpeedChangeFilter = TripSpeedChangeFilter()

  func filterTripSpeedChange(_ location: CLLocation) async -> Bool {
    guard await Self.tripSpeedChangeFilter.shouldAccept(location, lastOutputLocation) else { return false }
    return true
  }
}
