import CoreLocation
import OSLog

import DokoTypes
import DokoPacketManager
import DokoLogging
import DokoSharing

actor TripPositionDuplicateFilter: LocationFilter {
  private var lastLocation: CLLocation?

  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation) -> Bool {
    guard let last = lastLocation else {
      lastLocation = location
      return true
    }
    if location.timestamp == last.timestamp {
      DokoLogging.shared.postLoggingResponse(.coreLocation("TripPositionDuplicateFilter.timestamp"))
      return false
    }

    let distance = location.distance(from: last)
    if distance < appSettings.identicalTripPositionDistance {
      DokoLogging.shared.postLoggingResponse(.coreLocation("TripPositionDuplicateFilter.distance"))
      return false
    }
    lastLocation = location
    return true
  }

  func reset() {
    lastLocation = nil
  }
}

actor TripPositionCourseChangeFilter: LocationFilter {
  private var lastAcceptedLocation: CLLocation?

  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation) -> Bool {
    let course = location.course
    guard course >= 0 else {
      lastAcceptedLocation = nil
      return true
    }
    guard let lastLocation = lastAcceptedLocation else {
      lastAcceptedLocation = location
      return true
    }

    if abs(course - lastLocation.course) < appSettings.tripPositionCourseDeviation {
      let distance = location.distance(from: lastLocation)
      if distance > appSettings.maximumTripPositionDistance {
        lastAcceptedLocation = location
        return true
      }
      DokoLogging.shared.postLoggingResponse(.coreLocation("TripPositionCourseChangeFilter.course"))
      return false
    }
    lastAcceptedLocation = location
    return true
  }

  func reset() {
    lastAcceptedLocation = nil
  }
}

extension CoreLocationManager {
  static let tripPositionDuplicateFilter = TripPositionDuplicateFilter()
  static let tripPositionCourseChangeFilter = TripPositionCourseChangeFilter()

  func filterTripPosition(_ location: CLLocation) async {
    guard await Self.tripPositionDuplicateFilter.shouldAccept(location) else { return }
    guard await Self.tripPositionCourseChangeFilter.shouldAccept(location) else { return }

    let position = DokoPosition(position: location)
    var dokoResponses: DokoResponseDictionary = [:]
    dokoResponses[.position] = DokoCommandResponse(command: .tripPosition, response: .position(position))
    let dokoResponsePacket = DokoResponsePacket(type: .tripCorePosition, responses: dokoResponses)
    await DokoPacketManager.shared.appendDokoResponsePacket(dokoResponsePacket)
  }
}
