import CoreLocation
import OSLog

import DokoLogging
import DokoSharing

actor AccuracyLocationFilter: LocationFilter {
  let horizontalAccuracyThreshold: Double = 40
  let verticalAccuracyThreshold: Double = 50

  func shouldAccept(_ location: CLLocation) -> Bool {
    guard location.horizontalAccuracy >= 0 && location.verticalAccuracy >= 0 else {
      DokoLogging.shared.postLoggingResponse(.location("AccuracyLocationFilter.invalid"))
      return false
    }
    guard location.horizontalAccuracy < horizontalAccuracyThreshold else {
      DokoLogging.shared.postLoggingResponse(.location("AccuracyLocationFilter.horizontalAccuracy(\(String(format: "%.0f", location.horizontalAccuracy))"))
      return false
    }
    guard location.verticalAccuracy < verticalAccuracyThreshold else {
      DokoLogging.shared.postLoggingResponse(.location("AccuracyLocationFilter.verticalAccuracy(\(String(format: "%.0f", location.verticalAccuracy))"))
      return false
    }
    return true
  }

  func reset() {
  }
}

extension CoreLocationManager {
  static let accuracyFilter = AccuracyLocationFilter()

  func filterAccuracy(_ location: CLLocation) async -> CLLocation? {
    guard await Self.accuracyFilter.shouldAccept(location) else {
      return nil
    }
    return location
  }
}
