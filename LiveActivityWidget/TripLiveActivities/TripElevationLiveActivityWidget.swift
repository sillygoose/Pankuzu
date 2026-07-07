@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

struct TripElevationLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TripElevationActivityAttributes.self) { context in
      TripElevationLiveActivity(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: "car")
            .foregroundStyle(DesignTokens.Color.tripping)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Image(systemName: "record.circle")
            .foregroundStyle(DesignTokens.Color.record)
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

extension TripElevationActivityAttributes {
  fileprivate static var preview: TripElevationActivityAttributes {
    TripElevationActivityAttributes()
  }
}

extension TripElevationActivityAttributes.ContentState {
  fileprivate static var starting: TripElevationActivityAttributes.ContentState {
    TripElevationActivityAttributes.ContentState(
      tripState: .starting,
      duration: .seconds(0),
      distance: 0,
      rangeConsumed: 0,
      windSock: WindSock(
        course: 90,
        temperature: 15,
        conditions: "cloud.fill",
        windSpeed: 20,
        windDirection: 180,
        windCompassDirection: "S"
      )
    )
  }

  fileprivate static var active: TripElevationActivityAttributes.ContentState {
    TripElevationActivityAttributes.ContentState(
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

  fileprivate static var ended: TripElevationActivityAttributes.ContentState {
    TripElevationActivityAttributes.ContentState(
      tripState: .ended,
      duration: .seconds(7200),
      distance: 85.0,
      rangeConsumed: 92.0,
    )
  }
}

#Preview("Dynamic Island: Minimal", as: .dynamicIsland(.minimal), using: TripElevationActivityAttributes.preview) {
  TripElevationLiveActivityWidget()
} contentStates: {
  TripElevationActivityAttributes.ContentState.starting
  TripElevationActivityAttributes.ContentState.active
  TripElevationActivityAttributes.ContentState.ended
}

#Preview("Dynamic Island: Compact", as: .dynamicIsland(.compact), using: TripElevationActivityAttributes.preview) {
  TripElevationLiveActivityWidget()
} contentStates: {
  TripElevationActivityAttributes.ContentState.starting
  TripElevationActivityAttributes.ContentState.active
  TripElevationActivityAttributes.ContentState.ended
}

#Preview("Dynamic Island: Expanded", as: .dynamicIsland(.expanded), using: TripElevationActivityAttributes.preview) {
  TripElevationLiveActivityWidget()
} contentStates: {
  TripElevationActivityAttributes.ContentState.starting
  TripElevationActivityAttributes.ContentState.active
  TripElevationActivityAttributes.ContentState.ended
}
