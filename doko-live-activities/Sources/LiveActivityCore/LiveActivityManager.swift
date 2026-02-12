import Foundation
@preconcurrency import ActivityKit

import DokoLogging

@MainActor
public final class LiveActivityManager {
  public static let shared = LiveActivityManager()

  private init() {}

  private enum AnyManagedActivity {
    case trip(Activity<TripActivityAttributes>)
    case charge(Activity<ChargeActivityAttributes>)

    var id: String {
      switch self {
      case .trip(let trip): return trip.id
      case .charge(let charge): return charge.id
      }
    }

    func endImmediately() async {
      switch self {
      case .trip(let activity):
        let final = TripActivityAttributes.ContentState(tripState: .ended)
        let content = ActivityContent(state: final, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)

      case .charge(let activity):
        let final = ChargeActivityAttributes.ContentState(chargeState: .ended)
        let content = ActivityContent(state: final, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
      }
    }
  }

  private var managedActivity: AnyManagedActivity?

  public func startTrip() async {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip: Live Activities not enabled"))
      return
    }
    if let currentActivity = managedActivity {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip: already managing an activity"))
      await currentActivity.endImmediately()
    }
    let initial = TripActivityAttributes.ContentState(tripState: .starting)
    guard let activity = try? Activity.request(
      attributes: TripActivityAttributes(),
      content: ActivityContent(state: initial, staleDate: Date.now.addingTimeInterval(15))
    )
    else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip: Activity.request() failed"))
      return
    }
    self.managedActivity = .trip(activity)
    DokoLogging.shared.postLoggingResponse(.liveActivity("LiveActivityManager.startTrip"))
  }

  public func updateTrip(state: TripActivityAttributes.ContentState, staleAfter seconds: TimeInterval = 60) async {
    guard case .trip(let activity)? = managedActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.updateTrip: no activity"))
      return
    }
    let content = ActivityContent(state: state, staleDate: Date.now.addingTimeInterval(seconds))
    await activity.update(content)
    DokoLogging.shared.postLoggingResponse(.liveActivity("LiveActivityManager.updateTrip"))
  }

  public func endTrip(removeAfter seconds: TimeInterval = 15) async {
    guard case .trip(let activity)? = managedActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.endTrip: no activity"))
      return
    }
    let content = ActivityContent(state: TripActivityAttributes.ContentState(tripState: .ended), staleDate: nil)
    await activity.end(content, dismissalPolicy: .after(Date.now.addingTimeInterval(seconds)))
    self.managedActivity = nil
    DokoLogging.shared.postLoggingResponse(.liveActivity("LiveActivityManager.endTrip"))
  }

  public func startCharge() async {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startCharge: Live Activities not enabled"))
      return
    }
    if let currentActivity = managedActivity {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startCharge: already managing an activity"))
      await currentActivity.endImmediately()
    }
    let initial = ChargeActivityAttributes.ContentState(chargeState: .starting)
    guard let activity = try? Activity.request(
      attributes: ChargeActivityAttributes(),
      content: ActivityContent(state: initial, staleDate: Date.now.addingTimeInterval(15))
    )
    else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startCharge: Activity.request() failed"))
      return
    }
    self.managedActivity = .charge(activity)
    DokoLogging.shared.postLoggingResponse(.liveActivity("LiveActivityManager.startCharge"))
}

  public func updateCharge(state: ChargeActivityAttributes.ContentState, staleAfter seconds: TimeInterval = 60) async {
    guard case .charge(let activity)? = managedActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.updateCharge: no activity"))
      return
    }
    let content = ActivityContent(state: state, staleDate: Date.now.addingTimeInterval(seconds))
    await activity.update(content)
    DokoLogging.shared.postLoggingResponse(.liveActivity("LiveActivityManager.updateCharge"))
  }

  public func endCharge(removeAfter seconds: TimeInterval = 15) async {
    guard case .charge(let activity)? = managedActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.endCharge: no activity"))
      return
    }
    let content = ActivityContent(state: ChargeActivityAttributes.ContentState(chargeState: .ended), staleDate: nil)
    await activity.end(content, dismissalPolicy: .after(Date.now.addingTimeInterval(seconds)))
    self.managedActivity = nil
    DokoLogging.shared.postLoggingResponse(.liveActivity("LiveActivityManager.endCharge"))
  }
}
