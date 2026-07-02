@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

struct ChargeSessionLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ChargeSessionActivityAttributes.self) { context in
      ChargeSessionLiveActivity(context: context)
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

extension ChargeSessionActivityAttributes {
  fileprivate static var preview: ChargeSessionActivityAttributes {
    ChargeSessionActivityAttributes()
  }
}

 extension ChargeSessionActivityAttributes.ContentState {
   fileprivate static var starting: ChargeSessionActivityAttributes.ContentState {
     ChargeSessionActivityAttributes.ContentState(
       chargeState: .starting,
     )
   }

   fileprivate static var active: ChargeSessionActivityAttributes.ContentState {
     ChargeSessionActivityAttributes.ContentState(
      chargeState: .active,
       duration: .seconds(3661),
     )
   }

   fileprivate static var ended: ChargeSessionActivityAttributes.ContentState {
     ChargeSessionActivityAttributes.ContentState(
      chargeState: .ended,
       duration: .seconds(7200),
     )
   }
 }

 #Preview("Dynamic Island: Minimal", as: .dynamicIsland(.minimal), using: ChargeSessionActivityAttributes.preview) {
   ChargeSessionLiveActivityWidget()
 } contentStates: {
   ChargeSessionActivityAttributes.ContentState.starting
   ChargeSessionActivityAttributes.ContentState.active
   ChargeSessionActivityAttributes.ContentState.ended
 }

 #Preview("Dynamic Island: Compact", as: .dynamicIsland(.compact), using: ChargeSessionActivityAttributes.preview) {
   ChargeSessionLiveActivityWidget()
 } contentStates: {
   ChargeSessionActivityAttributes.ContentState.starting
   ChargeSessionActivityAttributes.ContentState.active
   ChargeSessionActivityAttributes.ContentState.ended
 }

 #Preview("Dynamic Island: Expanded", as: .dynamicIsland(.expanded), using: ChargeSessionActivityAttributes.preview) {
   ChargeSessionLiveActivityWidget()
 } contentStates: {
   ChargeSessionActivityAttributes.ContentState.starting
   ChargeSessionActivityAttributes.ContentState.active
   ChargeSessionActivityAttributes.ContentState.ended
 }
