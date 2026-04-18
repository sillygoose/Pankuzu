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

//struct ChargeLiveActivities: View {
//  let context: ActivityViewContext<ChargeActivityAttributes>
//  @Environment(\.activityFamily) var activityFamily
//
//  var body: some View {
//    if activityFamily == .small {
//      SmallChargeLiveActivities(context: context)
//    } else {
//      MediumChargeLiveActivities(context: context)
//    }
//  }
//}

extension ChargeActivityAttributes {
  fileprivate static var preview: ChargeActivityAttributes {
    ChargeActivityAttributes()
  }
}

/*
 extension TripActivityAttributes.ContentState {
   fileprivate static var starting: TripActivityAttributes.ContentState {
     TripActivityAttributes.ContentState(
       tripState: .starting,
       duration: .seconds(0),
       distance: .init(value: 0, unit: .kilometers),
       rangeConsumed: .init(value: 0, unit: .kilometers),
       windSock: WindSock(
         course: .init(value: 90, unit: .degrees),
         temperature: .init(value: 15, unit: .celsius),
         conditions: "cloud.fill",
         windSpeed: .init(value: 20, unit: .metersPerSecond),
         windDirection: .init(value: 180, unit: .degrees),
         windCompassDirection: "S"
       )
     )
   }

   fileprivate static var active: TripActivityAttributes.ContentState {
     TripActivityAttributes.ContentState(
       tripState: .active,
       duration: .seconds(3661),
       distance: .init(value: 42.5, unit: .kilometers),
       rangeConsumed: .init(value: 48.2, unit: .kilometers),
       windSock: WindSock(
         course: .init(value: 180, unit: .degrees),
         temperature: .init(value: 15, unit: .celsius),
         conditions: "cloud.fill",
         windSpeed: .init(value: 16, unit: .metersPerSecond),
         windDirection: .init(value: 180, unit: .degrees),
         windCompassDirection: "S"
       )
     )
   }

   fileprivate static var ended: TripActivityAttributes.ContentState {
     TripActivityAttributes.ContentState(
       tripState: .ended,
       duration: .seconds(7200),
       distance: .init(value: 85.0, unit: .kilometers),
       rangeConsumed: .init(value: 92.0, unit: .kilometers)
     )
   }
 }

 #Preview("Dynamic Island: Minimal", as: .dynamicIsland(.minimal), using: TripActivityAttributes.preview) {
   TripLiveActivityWidget()
 } contentStates: {
   TripActivityAttributes.ContentState.starting
   TripActivityAttributes.ContentState.active
   TripActivityAttributes.ContentState.ended
 }

 #Preview("Dynamic Island: Compact", as: .dynamicIsland(.compact), using: TripActivityAttributes.preview) {
   TripLiveActivityWidget()
 } contentStates: {
   TripActivityAttributes.ContentState.starting
   TripActivityAttributes.ContentState.active
   TripActivityAttributes.ContentState.ended
 }

 #Preview("Dynamic Island: Expanded", as: .dynamicIsland(.expanded), using: TripActivityAttributes.preview) {
   TripLiveActivityWidget()
 } contentStates: {
   TripActivityAttributes.ContentState.starting
   TripActivityAttributes.ContentState.active
   TripActivityAttributes.ContentState.ended
 }
 */
