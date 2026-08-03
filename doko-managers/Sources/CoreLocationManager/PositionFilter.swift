import CoreLocation
import OSLog

import DokoTypes
import DokoPacketManager
import DokoLogging
import DokoSharing

// MARK: - Position Filter Protocol

private protocol PositionFilter: Actor {
  func shouldAccept(_ location: CLLocation, _ previousPosition: CLLocation?) -> Bool
}

// MARK: - Horizontal Accuracy Filter

private actor HorizontalAccuracyFilter: PositionFilter {
  let horizontalAccuracyThreshold: Double = 40

  func shouldAccept(_ location: CLLocation, _ previousPosition: CLLocation?) -> Bool {
    guard location.horizontalAccuracy > 0 else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("horizontalAccuracyInvalid"))
      return false
    }
    guard location.horizontalAccuracy <= horizontalAccuracyThreshold else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("horizontalAccuracyBounds(\(String(format: "%.0f", location.horizontalAccuracy))"))
      return false
    }
    return true
  }
}

// MARK: - Position Change Filters

private actor PositionChangeFilter: PositionFilter {
  @Shared(.appSettings) var appSettings

  func shouldAccept(_ location: CLLocation, _ previousLocation: CLLocation?) -> Bool {
    guard let previousLocation else {
      DokoLogging.shared.postLoggingResponse(.coreLocation("PositionChange.initialPosition"), debugPacket: false)
      return true
    }
    guard location.timestamp != previousLocation.timestamp else { return false }

    let distanceChange = location.distance(from: previousLocation)
    guard distanceChange >= appSettings.identicalTripPositionDistance else { return false }
    if distanceChange >= appSettings.maximumTripPositionDistance {
      DokoLogging.shared.postLoggingResponse(.coreLocation("PositionChange.distance(\(String(format: "%.0f", distanceChange)))"), debugPacket: false)
      return true
    }
    
    if location.course >= 0 {
      if let courseChange = Self.courseDelta(location.course, previousLocation.course) {
        if abs(courseChange) >= appSettings.tripPositionCourseDeviation {
          DokoLogging.shared.postLoggingResponse(.coreLocation("PositionChange.course(\(String(format: "%.0f", courseChange)))"), debugPacket: false)
          return true
        }
      }
    }

    if location.speed >= 0 {
      let speedChnage = location.speed - previousLocation.speed
      if abs(speedChnage) >= appSettings.tripPositionSpeedDeviation {
        DokoLogging.shared.postLoggingResponse(.coreLocation("PositionChange.speed(\(String(format: "%.0f", speedChnage)))"), debugPacket: false)
        return true
      }
    }
    return false
  }

  // Signed angle (-180...180] from `previous` to `current`: positive is clockwise, negative
  // is counter-clockwise, accounting for the 0°/360° wraparound.
  private static func courseDelta(_ current: Double, _ previous: Double) -> Double? {
    guard current >= 0 && previous >= 0 else { return nil }
    var diff = (current - previous).truncatingRemainder(dividingBy: 360)
    if diff > 180 {
      diff -= 360
    } else if diff < -180 {
      diff += 360
    }
    return diff
  }
}

extension CoreLocationManager {
  fileprivate static let horizontalAccuracyFilter = HorizontalAccuracyFilter()
  fileprivate static let positionChangeFilter = PositionChangeFilter()

  func filterHorizontalAccuracy(_ location: CLLocation) async -> CLLocation? {
    guard await Self.horizontalAccuracyFilter.shouldAccept(location, lastOutputPosition) else { return nil }
    return location
  }
  
  func filterPosition(_ location: CLLocation) async {
    guard await Self.positionChangeFilter.shouldAccept(location, lastOutputPosition) else { return }

    var dokoResponses: DokoResponseDictionary = [:]
    dokoResponses[.position] = DokoCommandResponse(command: .tripPosition, response: .position(DokoPosition(position: location)))
    let dokoResponsePacket = DokoResponsePacket(type: .tripCorePosition, responses: dokoResponses)
    await DokoPacketManager.shared.appendDokoResponsePacket(dokoResponsePacket)
    lastOutputPosition = location
  }
}
