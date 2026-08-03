import CoreLocation
import OSLog

import DokoTypes
import DokoPacketManager
import DokoLogging
import DokoSharing

// MARK: - Elevation Filter Protocol

private protocol ElevationFilter: Actor {
  func shouldAccept(_ location: CLLocation, _ previousElevation: CLLocation?) -> Bool
}

// MARK: - Vertical Accuracy Filter

private actor VerticalAccuracyFilter: ElevationFilter {
  let verticalAccuracyThreshold: Double = 50

  func shouldAccept(_ location: CLLocation, _ previousElevation: CLLocation?) -> Bool {
    guard location.verticalAccuracy > 0 else {
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

// MARK: - Elevation Change Filter

private actor ElevationChangeFilter: ElevationFilter {
  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation, _ previousElevation: CLLocation?) -> Bool {
    guard let previousElevation else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("ElevationChange.initialElevation"), debugPacket: false)
      return true
    }
    guard location.timestamp != previousElevation.timestamp else { return false }

    let distanceChange = location.distance(from: previousElevation)
    if distanceChange >= appSettings.maximumTripElevationDistance {
      DokoLogging.shared.postLoggingResponse(.coreLocation("ElevationChange.distance(\(String(format: "%.0f", distanceChange)))"), debugPacket: false)
      return true
    }
    
    let elevationChnage = location.altitude - previousElevation.altitude
    if abs(elevationChnage) >= appSettings.minimumTripElevationChange {
      DokoLogging.shared.postLoggingResponse(.coreLocation("ElevationChange.elevation(\(String(format: "%.1f", elevationChnage)))"), debugPacket: false)
      return true
    }
    return false
  }
}

extension CoreLocationManager {
  fileprivate static let verticalAccuracyFilter = VerticalAccuracyFilter()
  fileprivate static let elevationChangeFilter = ElevationChangeFilter()

  func filterVerticalAccuracy(_ location: CLLocation) async -> CLLocation? {
    guard await Self.verticalAccuracyFilter.shouldAccept(location, lastOutputElevation) else { return nil }
    return location
  }
  
  func filterElevation(_ location: CLLocation) async {
    guard await Self.elevationChangeFilter.shouldAccept(location, lastOutputElevation) else { return }

    var dokoResponses: DokoResponseDictionary = [:]
    dokoResponses[.position] = DokoCommandResponse(command: .tripPosition, response: .position(DokoPosition(position: location)))
    let dokoResponsePacket = DokoResponsePacket(type: .tripCoreElevation, responses: dokoResponses)
    await DokoPacketManager.shared.appendDokoResponsePacket(dokoResponsePacket)
    lastOutputElevation = location
  }
}
