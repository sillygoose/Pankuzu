import CoreLocation
import OSLog

import DokoTypes
import DokoPacketManager
import DokoLogging
import DokoSharing

// MARK: - Horizontal Accuracy Filter

private actor HorizontalAccuracyFilter: PositionFilter {
  let horizontalAccuracyThreshold: Double = 40

  func shouldAccept(_ location: CLLocation, _ previousPosition: CLLocation?) -> Bool {
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
  fileprivate static let horizontalAccuracyFilter = HorizontalAccuracyFilter()

  func filterHorizontalAccuracy(_ location: CLLocation) async -> CLLocation? {
    guard await Self.horizontalAccuracyFilter.shouldAccept(location, lastOutputPosition) else { return nil }
    return location
  }
  
  func filterPosition(_ location: CLLocation) async {
    let shouldOutput: Bool = await filterPositionChange(location)
    guard shouldOutput else { return }

    var dokoResponses: DokoResponseDictionary = [:]
    dokoResponses[.position] = DokoCommandResponse(command: .tripPosition, response: .position(DokoPosition(position: location)))
    let dokoResponsePacket = DokoResponsePacket(type: .tripCorePosition, responses: dokoResponses)
    await DokoPacketManager.shared.appendDokoResponsePacket(dokoResponsePacket)
    lastOutputPosition = location
  }
}

// MARK: - Position Change Filters

private actor PositionChangeFilter: PositionFilter {
  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard let previousLocation else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("PositionChange.initialPosition"), debugPacket: true)
      return true
    }
    if location.timestamp == previousLocation.timestamp { return false }

    let distance = location.distance(from: previousLocation)
    guard distance >= appSettings.identicalTripPositionDistance else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("PositionChange.distance(\(String(format: "%.1f", distance)))"), debugPacket: true)
      return true
    }
    
    if location.course >= 0 {
      let deltaCourse = abs(location.course - previousLocation.course)
      if deltaCourse >= appSettings.tripPositionCourseDeviation {
        DokoLogging.shared.postLoggingResponse(.coreLocation("PositionChange.course(\(String(format: "%.1f", deltaCourse)))"), debugPacket: true)
        return true
      }
    }

    if location.speed >= 0 {
      let deltaSpeed = abs(location.speed - previousLocation.speed) * 3.6
      if deltaSpeed >= appSettings.tripPositionSpeedDeviation {
        DokoLogging.shared.postLoggingResponse(.coreLocation("PositionChange.speed(\(String(format: "%.1f", deltaSpeed)))"), debugPacket: true)
        return true
      }
    }
    return false
  }
}

extension CoreLocationManager {
  fileprivate static let positionChangeFilter = PositionChangeFilter()

  func filterPositionChange(_ location: CLLocation) async -> Bool {
    guard await Self.positionChangeFilter.shouldAccept(location, lastOutputPosition) else { return false }
    return true
  }
}
