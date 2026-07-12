@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

struct TripWindSockLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TripWindSockActivityAttributes.self) { context in
      TripWindSockLiveActivity(context: context)
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

extension TripWindSockActivityAttributes {
  fileprivate static var preview: TripWindSockActivityAttributes {
    TripWindSockActivityAttributes()
  }
}

extension TripWindSockActivityAttributes.ContentState {
  fileprivate static var starting: TripWindSockActivityAttributes.ContentState {
    TripWindSockActivityAttributes.ContentState(
      tripState: .starting,
      duration: .seconds(0),
      distance: 0,
      rangeConsumed: 0,
    )
  }

  fileprivate static var active: TripWindSockActivityAttributes.ContentState {
    TripWindSockActivityAttributes.ContentState(
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

  fileprivate static var ended: TripWindSockActivityAttributes.ContentState {
    TripWindSockActivityAttributes.ContentState(
      tripState: .ended,
      duration: .seconds(7200),
      distance: 85.0,
      rangeConsumed: 92.0,
    )
  }
}

#Preview("Dynamic Island: Minimal", as: .dynamicIsland(.minimal), using: TripWindSockActivityAttributes.preview) {
  TripWindSockLiveActivityWidget()
} contentStates: {
  TripWindSockActivityAttributes.ContentState.starting
  TripWindSockActivityAttributes.ContentState.active
  TripWindSockActivityAttributes.ContentState.ended
}

#Preview("Dynamic Island: Compact", as: .dynamicIsland(.compact), using: TripWindSockActivityAttributes.preview) {
  TripWindSockLiveActivityWidget()
} contentStates: {
  TripWindSockActivityAttributes.ContentState.starting
  TripWindSockActivityAttributes.ContentState.active
  TripWindSockActivityAttributes.ContentState.ended
}

#Preview("Dynamic Island: Expanded", as: .dynamicIsland(.expanded), using: TripWindSockActivityAttributes.preview) {
  TripWindSockLiveActivityWidget()
} contentStates: {
  TripWindSockActivityAttributes.ContentState.starting
  TripWindSockActivityAttributes.ContentState.active
  TripWindSockActivityAttributes.ContentState.ended
}
