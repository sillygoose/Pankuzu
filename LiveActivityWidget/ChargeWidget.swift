@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

struct ChargeLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ChargeActivityAttributes.self) { context in
      ChargeLockScreen(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: "ev.charger")
            .foregroundStyle(DesignTokens.Color.charging)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Image(systemName: "record.circle")
            .foregroundStyle(DesignTokens.Color.record)
        }
        DynamicIslandExpandedRegion(.bottom) {
          ChargeActiveView(
            duration: context.state.duration,
            stateOfCharge: context.state.stateOfCharge,
            rangeAdded: context.state.rangeAdded,
            measuredPower: context.state.measuredPower
          )        }
      } compactLeading: {
        Image(systemName: "ev.charger")
          .foregroundStyle(DesignTokens.Color.charging)
      } compactTrailing: {
        Image(systemName: "record.circle")
          .foregroundStyle(DesignTokens.Color.record)
      } minimal: {
        Image(systemName: "record.circle")
          .foregroundStyle(DesignTokens.Color.record)
      }
    }
  }
}
