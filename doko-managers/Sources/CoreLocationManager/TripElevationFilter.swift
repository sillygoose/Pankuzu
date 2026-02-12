import CoreLocation
import OSLog

import DokoTypes
import DokoPacketManager
import DokoLogging
import DokoSharing

actor TripElevationFilter: LocationFilter {
  private var lastLocation: CLLocation?

  @Shared(.maximumTripElevationDistance) var maximumTripElevationDistance
  @Shared(.minimumTripElevationChange) var minimumTripElevationChange

  func shouldAccept(_ location: CLLocation) -> Bool {
    guard let last = lastLocation else {
      lastLocation = location
      return true
    }
    if location.timestamp == last.timestamp {
      DokoLogging.shared.postLoggingResponse(.location("TripElevationFilter.timestamp"))
      return false
    }

    let distance = location.distance(from: last)
    if distance > maximumTripElevationDistance {
      lastLocation = location
      return true
    }

    if abs(last.altitude - location.altitude) < minimumTripElevationChange {
      DokoLogging.shared.postLoggingResponse(.location("TripElevationFilter.change"))
      return false
    }

    lastLocation = location
    return true
  }

  func reset() {
    lastLocation = nil
  }
}
extension CoreLocationManager {
  static let tripElevationFilter = TripElevationFilter()

  func filterTripElevation(_ location: CLLocation) async {
    guard await Self.tripElevationFilter.shouldAccept(location) else { return }

    let position = DokoPosition(position: location)
    var dokoResponses: DokoResponseDictionary = [:]
    dokoResponses[.position] = DokoCommandResponse(command: .tripPosition, response: .position(position))
    let dokoResponsePacket = DokoResponsePacket(type: .tripCoreElevation, responses: dokoResponses)
    await DokoPacketManager.shared.appendDokoResponsePacket(dokoResponsePacket)
  }
}
