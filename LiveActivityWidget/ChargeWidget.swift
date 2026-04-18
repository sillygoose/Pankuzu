@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

//struct TripLiveActivityWidget: Widget {
//  var body: some WidgetConfiguration {
//    ActivityConfiguration(for: TripActivityAttributes.self) { context in
//      TripLiveActivities(context: context)
//    } dynamicIsland: { context in
//      DynamicIsland {
//        DynamicIslandExpandedRegion(.leading) {
//          Image(systemName: "car")
//            .foregroundStyle(DesignTokens.Color.tripping)
//        }
//        DynamicIslandExpandedRegion(.trailing) {
//          Image(systemName: "record.circle")
//            .foregroundStyle(DesignTokens.Color.record)
//        }
//      } compactLeading: {
//        Image(systemName: "car")
//          .foregroundStyle(DesignTokens.Color.tripping)
//      } compactTrailing: {
//        Image(systemName: "record.circle")
//          .foregroundStyle(DesignTokens.Color.record)
//      } minimal: {
//        Image(systemName: "record.circle")
//          .foregroundStyle(DesignTokens.Color.record)
//      }
//    }
//    .supplementalActivityFamilies([.small])
//  }
//}

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
//        DynamicIslandExpandedRegion(.bottom) {
//          ChargeActiveView(
//            duration: context.state.duration,
//            stateOfCharge: context.state.stateOfCharge,
//            rangeAdded: context.state.rangeAdded,
//            measuredPower: context.state.measuredPower
//          )
//        }
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

struct ChargeLiveActivities: View {
  let context: ActivityViewContext<ChargeActivityAttributes>
  @Environment(\.activityFamily) var activityFamily

  var body: some View {
    if activityFamily == .small {
      SmallChargeLiveActivities(context: context)
    } else {
      MediumChargeLiveActivities(context: context)
    }
  }
}

extension ChargeActivityAttributes {
  fileprivate static var preview: ChargeActivityAttributes {
    ChargeActivityAttributes()
  }
}
