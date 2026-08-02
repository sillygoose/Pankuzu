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

// MARK: - Position/Elevation Filtering

extension CoreLocationManager {


  func resetLocationFilters() async {
    lastOutputPosition = nil
    lastOutputElevation = nil
  }
}

// MARK: - Horizontal Accuracy Filter

actor HorizontalAccuracyFilter: LocationFilter {
  let horizontalAccuracyThreshold: Double = 40

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard location.horizontalAccuracy >= 0 else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("horizontalAccuracyInvalid"))
      return false
    }
    guard location.horizontalAccuracy < horizontalAccuracyThreshold else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("horizontalAccuracyBounds(\(String(format: "%.0f", location.horizontalAccuracy))"))
      return false
    }
    return true
  }
}

extension CoreLocationManager {
  static let horizontalAccuracyFilter = HorizontalAccuracyFilter()

  func filterHorizontalAccuracy(_ location: CLLocation) async -> CLLocation? {
    guard await Self.horizontalAccuracyFilter.shouldAccept(location, lastOutputPosition) else { return nil }
    return location
  }
  
  func filterPosition(_ location: CLLocation) async {
    let shouldOutput: Bool
    if await filterPositionChange(location) {
      shouldOutput = true
    } else if await filterCourseChange(location) {
      shouldOutput = true
    } else if await filterSpeedChange(location) {
      shouldOutput = true
    } else {
      shouldOutput = false
    }
    guard shouldOutput else { return }

    var dokoResponses: DokoResponseDictionary = [:]
    dokoResponses[.position] = DokoCommandResponse(command: .tripPosition, response: .position(DokoPosition(position: location)))
    let dokoResponsePacket = DokoResponsePacket(type: .tripCorePosition, responses: dokoResponses)
    await DokoPacketManager.shared.appendDokoResponsePacket(dokoResponsePacket)
    lastOutputPosition = location
  }
}

// MARK: - Vertical Accuracy Filter

actor VerticalAccuracyFilter: LocationFilter {
  let verticalAccuracyThreshold: Double = 50

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard location.horizontalAccuracy >= 0 else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("verticalAccuracyInvalid"))
      return false
    }
    guard location.verticalAccuracy < verticalAccuracyThreshold else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("verticalAccuracyBounds(\(String(format: "%.0f", location.verticalAccuracy))"))
      return false
    }
    return true
  }
}

extension CoreLocationManager {
  static let verticalAccuracyFilter = VerticalAccuracyFilter()

  func filterVerticalAccuracy(_ location: CLLocation) async -> CLLocation? {
    guard await Self.verticalAccuracyFilter.shouldAccept(location, lastOutputElevation) else { return nil }
    return location
  }
  
  func filterElevation(_ location: CLLocation) async {
    let shouldOutput: Bool = await filterElevationChange(location)
    guard shouldOutput else { return }

    var dokoResponses: DokoResponseDictionary = [:]
    dokoResponses[.position] = DokoCommandResponse(command: .tripPosition, response: .position(DokoPosition(position: location)))
    let dokoResponsePacket = DokoResponsePacket(type: .tripCoreElevation, responses: dokoResponses)
    await DokoPacketManager.shared.appendDokoResponsePacket(dokoResponsePacket)
    lastOutputElevation = location
  }
}

// MARK: - Trip Position Change Filters

actor TripPositionChangeFilter: LocationFilter {
  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard let last = previousLocation else { return true }
    if location.timestamp == last.timestamp {
      DokoLogging.shared.postLoggingResponse(.coreLocation("TripPositionChangeFilter.timestamp"), debugPacket: true)
      return false
    }

    let distance = location.distance(from: last)
    if distance < appSettings.identicalTripPositionDistance {
      DokoLogging.shared.postLoggingResponse(.coreLocation("TripPositionChangeFilter.distance"), debugPacket: true)
      return false
    }
    return true
  }
}

extension CoreLocationManager {
  static let tripPositionChangeFilter = TripPositionChangeFilter()

  func filterPositionChange(_ location: CLLocation) async -> Bool {
    guard await Self.tripPositionChangeFilter.shouldAccept(location, lastOutputPosition) else { return false }
    return true
  }
}

// MARK: - Trip Elevation Charge Filter

actor TripElevationChangeFilter: LocationFilter {
  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard let last = previousLocation else { return true }
    if location.timestamp == last.timestamp {
      DokoLogging.shared.postLoggingResponse(.coreLocation("TripElevationChangeFilter.timestamp"), debugPacket: true)
      return false
    }

    let distance = location.distance(from: last)
    if distance > appSettings.maximumTripElevationDistance { return true }

    if abs(last.altitude - location.altitude) < appSettings.minimumTripElevationChange {
      DokoLogging.shared.postLoggingResponse(.coreLocation("TripElevationChangeFilter.change"), debugPacket: true)
      return false
    }
    return true
  }
}

extension CoreLocationManager {
  static let tripElevationChangeFilter = TripElevationChangeFilter()

  func filterElevationChange(_ location: CLLocation) async -> Bool {
    guard await Self.tripElevationChangeFilter.shouldAccept(location, lastOutputPosition) else { return false }
    return true
  }
}

// MARK: - Trip Course Change Filter

actor TripCourseChangeFilter: LocationFilter {
  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard location.course >= 0, let previousLocation else { return false }
    guard abs(location.course - previousLocation.course) > appSettings.tripPositionCourseDeviation else { return false }
    DokoLogging.shared.postLoggingResponse(.coreLocation("TripCourseChangeFilter.course"), debugPacket: true)
    return true
  }
}

extension CoreLocationManager {
  static let tripCourseChangeFilter = TripCourseChangeFilter()

  func filterCourseChange(_ location: CLLocation) async -> Bool {
    guard await Self.tripCourseChangeFilter.shouldAccept(location, lastOutputPosition) else { return false }
    return true
  }
}

// MARK: - Trip Speed Change Filter

actor TripSpeedChangeFilter: LocationFilter {
  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard location.speed >= 0, let previousLocation else { return false }
    guard (abs(location.speed - previousLocation.speed) * 3.6) > appSettings.tripPositionSpeedDeviation else { return false }
    DokoLogging.shared.postLoggingResponse(.coreLocation("TripSpeedChangeFilter.speed"), debugPacket: true)
    return true
  }
}

extension CoreLocationManager {
  static let tripSpeedChangeFilter = TripSpeedChangeFilter()

  func filterSpeedChange(_ location: CLLocation) async -> Bool {
    guard await Self.tripSpeedChangeFilter.shouldAccept(location, lastOutputPosition) else { return false }
    return true
  }
}
