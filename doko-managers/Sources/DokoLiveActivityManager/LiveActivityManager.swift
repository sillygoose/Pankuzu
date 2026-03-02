import Foundation
@preconcurrency import ActivityKit

import DokoLogging
import DokoSharing

@MainActor
public final class LiveActivityManager {
  public static let shared = LiveActivityManager()

  private init() {
    startAccessoryNameObservation()
    startForegroundObservation()
  }

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

  private enum PendingActivity {
    case trip
    case charge
  }

  private var pendingActivity: PendingActivity?

  private func startForegroundObservation() {
    Task {
      for await _ in NotificationCenter.default.notifications(named: Notification.Name("UIApplicationDidBecomeActiveNotification")) {
        guard let pending = self.pendingActivity else { continue }
        self.pendingActivity = nil
        switch pending {
        case .trip: await self.startTrip()
        case .charge: await self.startCharge()
        }
      }
    }
  }

  private func startAccessoryNameObservation() {
    @Shared(.connectedAccessory) var observedAccessoryName
    Task { [weak self] in
      guard let self else { return }
      var oldAccessoryName: String? = nil
      for await newAccessoryName in $observedAccessoryName.publisher.values {
        if Task.isCancelled { break }
        guard oldAccessoryName != newAccessoryName else { continue }
        if newAccessoryName == nil {
          guard let activity = self.managedActivity else { continue }
          DokoLogging.shared.postLoggingResponse(.liveActivity("ending activity due to disconnect"))
          await activity.endImmediately()
          self.managedActivity = nil
          self.pendingActivity = nil
        }
        oldAccessoryName = newAccessoryName
      }
    }
  }

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
    let activity: Activity<TripActivityAttributes>
    do {
      activity = try Activity.request(
        attributes: TripActivityAttributes(),
        content: ActivityContent(state: initial, staleDate: Date.now.addingTimeInterval(15))
      )
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip: \(error.localizedDescription)"))
      pendingActivity = .trip
      return
    }
    self.managedActivity = .trip(activity)
    DokoLogging.shared.postLoggingResponse(.liveActivity(".startTrip"))
  }

  public func updateTrip(state: TripActivityAttributes.ContentState, staleAfter seconds: TimeInterval = 60) async {
    guard case .trip(let activity)? = managedActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.updateTrip: no activity"))
      return
    }
    let content = ActivityContent(state: state, staleDate: Date.now.addingTimeInterval(seconds))
    await activity.update(content)
    DokoLogging.shared.postLoggingResponse(.liveActivity(".updateTrip"))
  }

  public func endTrip(removeAfter seconds: TimeInterval = 15) async {
    guard case .trip(let activity)? = managedActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.endTrip: no activity"))
      return
    }
    let content = ActivityContent(state: TripActivityAttributes.ContentState(tripState: .ended), staleDate: nil)
    await activity.end(content, dismissalPolicy: .after(Date.now.addingTimeInterval(seconds)))
    self.managedActivity = nil
    self.pendingActivity = nil
    DokoLogging.shared.postLoggingResponse(.liveActivity(".endTrip"))
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
    let activity: Activity<ChargeActivityAttributes>
    do {
      activity = try Activity.request(
        attributes: ChargeActivityAttributes(),
        content: ActivityContent(state: initial, staleDate: Date.now.addingTimeInterval(15))
      )
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startCharge: \(error.localizedDescription)"))
      pendingActivity = .charge
      return
    }
    self.managedActivity = .charge(activity)
    DokoLogging.shared.postLoggingResponse(.liveActivity(".startCharge"))
}

  public func updateCharge(state: ChargeActivityAttributes.ContentState, staleAfter seconds: TimeInterval = 60) async {
    guard case .charge(let activity)? = managedActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.updateCharge: no activity"))
      return
    }
    let content = ActivityContent(state: state, staleDate: Date.now.addingTimeInterval(seconds))
    await activity.update(content)
    DokoLogging.shared.postLoggingResponse(.liveActivity(".updateCharge"))
  }

  public func endCharge(removeAfter seconds: TimeInterval = 15) async {
    guard case .charge(let activity)? = managedActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.endCharge: no activity"))
      return
    }
    let content = ActivityContent(state: ChargeActivityAttributes.ContentState(chargeState: .ended), staleDate: nil)
    await activity.end(content, dismissalPolicy: .after(Date.now.addingTimeInterval(seconds)))
    self.managedActivity = nil
    self.pendingActivity = nil
    DokoLogging.shared.postLoggingResponse(.liveActivity(".endCharge"))
  }
}
