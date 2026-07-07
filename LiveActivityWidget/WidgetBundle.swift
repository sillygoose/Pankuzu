import WidgetKit
import SwiftUI

@main
struct LiveActivityWidgetBundle: WidgetBundle {
  var body: some Widget {
    TripWindSockLiveActivityWidget()
    TripElevationLiveActivityWidget()
    TripEfficiencyLiveActivityWidget()
    ChargeSessionLiveActivityWidget()
  }
}
