import CoreLocation
import OSLog

import DokoLogging
import DokoSharing

protocol LocationFilter: Actor {
  func shouldAccept(_ location: CLLocation) -> Bool
  func reset()
}

extension CoreLocationManager {
  func filterLocation(_ location: CLLocation) async {
    await filterTripPosition(location)
    await filterTripElevation(location)
  }

  func resetLocationFilters() async {
    await Self.accuracyFilter.reset()
    await Self.tripPositionDuplicateFilter.reset()
    await Self.tripPositionCourseChangeFilter.reset()
    await Self.tripElevationFilter.reset()
  }
}
