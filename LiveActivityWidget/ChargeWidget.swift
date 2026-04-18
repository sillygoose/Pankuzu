@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

struct ChargeLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ChargeActivityAttributes.self) { context in
      ChargeLiveActivities(context: context)
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

extension ChargeActivityAttributes {
  fileprivate static var preview: ChargeActivityAttributes {
    ChargeActivityAttributes()
  }
}

 extension ChargeActivityAttributes.ContentState {
   fileprivate static var starting: ChargeActivityAttributes.ContentState {
     ChargeActivityAttributes.ContentState(
       chargeState: .starting,
     )
   }

   fileprivate static var active: ChargeActivityAttributes.ContentState {
     ChargeActivityAttributes.ContentState(
      chargeState: .active,
       duration: .seconds(3661),
     )
   }

   fileprivate static var ended: ChargeActivityAttributes.ContentState {
     ChargeActivityAttributes.ContentState(
      chargeState: .ended,
       duration: .seconds(7200),
     )
   }
 }

 #Preview("Dynamic Island: Minimal", as: .dynamicIsland(.minimal), using: ChargeActivityAttributes.preview) {
   ChargeLiveActivityWidget()
 } contentStates: {
   ChargeActivityAttributes.ContentState.starting
   ChargeActivityAttributes.ContentState.active
   ChargeActivityAttributes.ContentState.ended
 }

 #Preview("Dynamic Island: Compact", as: .dynamicIsland(.compact), using: ChargeActivityAttributes.preview) {
   ChargeLiveActivityWidget()
 } contentStates: {
   ChargeActivityAttributes.ContentState.starting
   ChargeActivityAttributes.ContentState.active
   ChargeActivityAttributes.ContentState.ended
 }

 #Preview("Dynamic Island: Expanded", as: .dynamicIsland(.expanded), using: ChargeActivityAttributes.preview) {
   ChargeLiveActivityWidget()
 } contentStates: {
   ChargeActivityAttributes.ContentState.starting
   ChargeActivityAttributes.ContentState.active
   ChargeActivityAttributes.ContentState.ended
 }
