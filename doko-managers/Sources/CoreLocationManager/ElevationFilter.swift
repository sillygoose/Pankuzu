import CoreLocation
import OSLog

import DokoTypes
import DokoPacketManager
import DokoLogging
import DokoSharing

// MARK: - Vertical Accuracy Filter

private actor VerticalAccuracyFilter: ElevationFilter {
  let verticalAccuracyThreshold: Double = 50

  func shouldAccept(_ location: CLLocation, _ previousElevation: CLLocation?) -> Bool {
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
  fileprivate static let verticalAccuracyFilter = VerticalAccuracyFilter()

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

// MARK: - Elevation Change Filter

private actor ElevationChange: ElevationFilter {
  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation, _ previousElevation: CLLocation?) -> Bool {
    guard let previousElevation else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("ElevationChange.initialElevation"), debugPacket: true)
      return true
    }
    if location.timestamp == previousElevation.timestamp { return false }

    let distance = location.distance(from: previousElevation)
    if distance >= appSettings.maximumTripElevationDistance {
      DokoLogging.shared.postLoggingResponse(.coreLocation("ElevationChange.distance(\(String(format: "%.1f", distance)))"), debugPacket: true)
      return true
    }

    let deltaElevation = abs(previousElevation.altitude - location.altitude)
    guard deltaElevation >= appSettings.minimumTripElevationChange else { return false }
    DokoLogging.shared.postLoggingResponse(.coreLocation("ElevationChange.elevation(\(String(format: "%.01", deltaElevation)))"), debugPacket: true)
    return true
  }
}

extension CoreLocationManager {
  fileprivate static let elevationChangeFilter = ElevationChange()

  func filterElevationChange(_ location: CLLocation) async -> Bool {
    guard await Self.elevationChangeFilter.shouldAccept(location, lastOutputElevation) else { return false }
    return true
  }
}
