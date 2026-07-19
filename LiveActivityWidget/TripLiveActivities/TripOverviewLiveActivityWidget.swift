@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

struct TripOverviewLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TripOverviewActivityAttributes.self) { context in
      TripOverviewLiveActivity(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {}
        DynamicIslandExpandedRegion(.center) {
          Text("Trip Starting")
            .foregroundStyle(DesignTokens.Color.primary)
            .font(DesignTokens.Font.title)
        }
      } compactLeading: {
        Image(systemName: "car")
          .foregroundStyle(DesignTokens.Color.tripping)
      } compactTrailing: {
        Image(systemName: "record.circle")
          .foregroundStyle(DesignTokens.Color.record)
      } minimal: {
        Image(systemName: "record.circle")
          .foregroundStyle(DesignTokens.Color.record)
      }
    }
    .supplementalActivityFamilies([.small])
  }
}

extension TripOverviewActivityAttributes {
  fileprivate static var preview: TripOverviewActivityAttributes {
    TripOverviewActivityAttributes()
  }
}

extension TripOverviewActivityAttributes.ContentState {
  fileprivate static var starting: TripOverviewActivityAttributes.ContentState {
    TripOverviewActivityAttributes.ContentState(
      tripState: .starting,
      duration: .seconds(0),
      distance: 0,
      rangeConsumed: 0,
    )
  }

  fileprivate static var active: TripOverviewActivityAttributes.ContentState {
    TripOverviewActivityAttributes.ContentState(
      tripState: .active,
      duration: .seconds(3661),
      distance: 42.5,
      rangeConsumed: 48.2,
      windSock: WindSock(
        course: 180,
        temperature: 15,
        conditions: "cloud.fill",
        windSpeed: 16,
        windDirection: 180,
        windCompassDirection: "S"
      )
    )
  }

  fileprivate static var ended: TripOverviewActivityAttributes.ContentState {
    TripOverviewActivityAttributes.ContentState(
      tripState: .ended,
      duration: .seconds(7200),
      distance: 85.0,
      rangeConsumed: 92.0,
    )
  }
}

#Preview("Dynamic Island: Minimal", as: .dynamicIsland(.minimal), using: TripOverviewActivityAttributes.preview) {
  TripOverviewLiveActivityWidget()
} contentStates: {
  TripOverviewActivityAttributes.ContentState.starting
  TripOverviewActivityAttributes.ContentState.active
  TripOverviewActivityAttributes.ContentState.ended
}

#Preview("Dynamic Island: Compact", as: .dynamicIsland(.compact), using: TripOverviewActivityAttributes.preview) {
  TripOverviewLiveActivityWidget()
} contentStates: {
  TripOverviewActivityAttributes.ContentState.starting
  TripOverviewActivityAttributes.ContentState.active
  TripOverviewActivityAttributes.ContentState.ended
}

#Preview("Dynamic Island: Expanded", as: .dynamicIsland(.expanded), using: TripOverviewActivityAttributes.preview) {
  TripOverviewLiveActivityWidget()
} contentStates: {
  TripOverviewActivityAttributes.ContentState.starting
  TripOverviewActivityAttributes.ContentState.active
  TripOverviewActivityAttributes.ContentState.ended
}
