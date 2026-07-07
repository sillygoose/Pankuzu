@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

struct TripEfficiencyLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TripEfficiencyActivityAttributes.self) { context in
      TripEfficiencyLiveActivity(context: context)
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

extension TripEfficiencyActivityAttributes {
  fileprivate static var preview: TripEfficiencyActivityAttributes {
    TripEfficiencyActivityAttributes()
  }
}

extension TripEfficiencyActivityAttributes.ContentState {
  fileprivate static var starting: TripEfficiencyActivityAttributes.ContentState {
    TripEfficiencyActivityAttributes.ContentState(
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

  fileprivate static var active: TripEfficiencyActivityAttributes.ContentState {
    TripEfficiencyActivityAttributes.ContentState(
      tripState: .active,
      duration: .seconds(3661),
      distance: 42.5,
      efficiency: 5.2,
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

  fileprivate static var ended: TripEfficiencyActivityAttributes.ContentState {
    TripEfficiencyActivityAttributes.ContentState(
      tripState: .ended,
      duration: .seconds(7200),
      distance: 85.0,
      efficiency: 5.8,
      rangeConsumed: 92.0,
    )
  }
}

#Preview("Dynamic Island: Minimal", as: .dynamicIsland(.minimal), using: TripEfficiencyActivityAttributes.preview) {
  TripEfficiencyLiveActivityWidget()
} contentStates: {
  TripEfficiencyActivityAttributes.ContentState.starting
  TripEfficiencyActivityAttributes.ContentState.active
  TripEfficiencyActivityAttributes.ContentState.ended
}

#Preview("Dynamic Island: Compact", as: .dynamicIsland(.compact), using: TripEfficiencyActivityAttributes.preview) {
  TripEfficiencyLiveActivityWidget()
} contentStates: {
  TripEfficiencyActivityAttributes.ContentState.starting
  TripEfficiencyActivityAttributes.ContentState.active
  TripEfficiencyActivityAttributes.ContentState.ended
}

#Preview("Dynamic Island: Expanded", as: .dynamicIsland(.expanded), using: TripEfficiencyActivityAttributes.preview) {
  TripEfficiencyLiveActivityWidget()
} contentStates: {
  TripEfficiencyActivityAttributes.ContentState.starting
  TripEfficiencyActivityAttributes.ContentState.active
  TripEfficiencyActivityAttributes.ContentState.ended
}
