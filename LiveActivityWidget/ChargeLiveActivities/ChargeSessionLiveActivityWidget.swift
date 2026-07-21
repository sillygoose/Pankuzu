@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

struct ChargeOverviewLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ChargeOverviewActivityAttributes.self) { context in
      ChargeOverviewLiveActivity(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {}
        DynamicIslandExpandedRegion(.center) {
          Text("Charge Starting")
            .foregroundStyle(DesignTokens.Color.primary)
            .font(DesignTokens.Font.title)
        }
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
    .supplementalActivityFamilies([.small])
  }
}

extension ChargeOverviewActivityAttributes {
  fileprivate static var preview: ChargeOverviewActivityAttributes {
    ChargeOverviewActivityAttributes()
  }
}

 extension ChargeOverviewActivityAttributes.ContentState {
   fileprivate static var starting: ChargeOverviewActivityAttributes.ContentState {
     ChargeOverviewActivityAttributes.ContentState(
       chargeState: .starting,
     )
   }

   fileprivate static var active: ChargeOverviewActivityAttributes.ContentState {
     ChargeOverviewActivityAttributes.ContentState(
      chargeState: .active,
       duration: .seconds(3661),
     )
   }

   fileprivate static var ended: ChargeOverviewActivityAttributes.ContentState {
     ChargeOverviewActivityAttributes.ContentState(
      chargeState: .ended,
       duration: .seconds(7200),
     )
   }
 }

 #Preview("Dynamic Island: Minimal", as: .dynamicIsland(.minimal), using: ChargeOverviewActivityAttributes.preview) {
   ChargeOverviewLiveActivityWidget()
 } contentStates: {
   ChargeOverviewActivityAttributes.ContentState.starting
   ChargeOverviewActivityAttributes.ContentState.active
   ChargeOverviewActivityAttributes.ContentState.ended
 }

 #Preview("Dynamic Island: Compact", as: .dynamicIsland(.compact), using: ChargeOverviewActivityAttributes.preview) {
   ChargeOverviewLiveActivityWidget()
 } contentStates: {
   ChargeOverviewActivityAttributes.ContentState.starting
   ChargeOverviewActivityAttributes.ContentState.active
   ChargeOverviewActivityAttributes.ContentState.ended
 }

 #Preview("Dynamic Island: Expanded", as: .dynamicIsland(.expanded), using: ChargeOverviewActivityAttributes.preview) {
   ChargeOverviewLiveActivityWidget()
 } contentStates: {
   ChargeOverviewActivityAttributes.ContentState.starting
   ChargeOverviewActivityAttributes.ContentState.active
   ChargeOverviewActivityAttributes.ContentState.ended
 }
