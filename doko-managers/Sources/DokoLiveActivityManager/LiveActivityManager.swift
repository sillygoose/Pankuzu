import Foundation
import UIKit
import OSLog
@preconcurrency import ActivityKit

import Dependencies
@_exported import DokoDesignTokens
@_exported import DokoExtensions

import DokoTypes
import DokoLogging
import DokoSharing

@MainActor
public final class LiveActivityManager {
  public static let shared = LiveActivityManager()
  private let logger = Logger(subsystem: "com.unchan.doko", category: "LiveActivityManager")

  private init() {
    endOrphanedActivities()
    startAccessoryNameObservation()
    startForegroundObservation()
    startPushToStartTokenObservation()
  }

  private func endOrphanedActivities() {
    Task {
      for activity in Activity<TripActivityAttributes>.activities {
        let final = TripActivityAttributes.ContentState(tripState: .ended)
        let content = ActivityContent(state: final, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        DokoLogging.shared.postLoggingResponse(.liveActivity("ended orphaned trip activity \(activity.id)"))
      }
      for activity in Activity<ChargeActivityAttributes>.activities {
        let final = ChargeActivityAttributes.ContentState(chargeState: .ended)
        let content = ActivityContent(state: final, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        DokoLogging.shared.postLoggingResponse(.liveActivity("ended orphaned charge activity \(activity.id)"))
      }
    }
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
  private var tripPushToStartToken: Data?

  private enum PendingActivity {
    case trip
    case charge
  }

  private var pendingActivity: PendingActivity?

  private func startPushToStartTokenObservation() {
    Task {
      for await token in Activity<TripActivityAttributes>.pushToStartTokenUpdates {
        tripPushToStartToken = token
        DokoLogging.shared.postLoggingResponse(.liveActivity("tripPushToStartToken updated"))
      }
    }
  }

  private func startForegroundObservation() {
    let names: [Notification.Name] = [
      UIApplication.didBecomeActiveNotification,
      UIScene.didActivateNotification,
    ]
    for name in names {
      Task {
        for await _ in NotificationCenter.default.notifications(named: name) {
          guard let pending = self.pendingActivity else { continue }
          self.pendingActivity = nil
          switch pending {
          case .trip: await self.startTrip()
          case .charge: await self.startCharge()
          }
        }
      }
    }
  }

  private func startAccessoryNameObservation() {
    @Shared(.connectedAccessoryName) var observedAccessoryName
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
    @Dependency(\.date.now) var now
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip: Live Activities not enabled"))
      return
    }
    if let currentActivity = managedActivity {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip: already managing an activity"))
      await currentActivity.endImmediately()
    }

    let hasActiveScene = UIApplication.shared.connectedScenes
      .contains { $0.activationState == .foregroundActive }

    if !hasActiveScene, let token = tripPushToStartToken {
      await pushToStartTrip(token: token)
      Task {
        for await activity in Activity<TripActivityAttributes>.activityUpdates {
          guard case .trip(_) = self.managedActivity else {
            self.managedActivity = .trip(activity)
            DokoLogging.shared.postLoggingResponse(.liveActivity(".startTrip via push-to-start"))
            break
          }
        }
      }
      return
    }

    guard hasActiveScene else {
      DokoLogging.shared.postLoggingResponse(.liveActivity("startTrip: no active scene and no push-to-start token, deferring"))
      pendingActivity = .trip
      return
    }

    let initial = TripActivityAttributes.ContentState(tripState: .starting)
    let activity: Activity<TripActivityAttributes>
    let staleDate: Double = 5
    do {
      activity = try Activity.request(
        attributes: TripActivityAttributes(),
        content: ActivityContent(state: initial, staleDate: now.addingTimeInterval(staleDate)),
        pushType: .token
      )
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip failed: \(error)"))
      return
    }
    self.managedActivity = .trip(activity)
    DokoLogging.shared.postLoggingResponse(.liveActivity(".startTrip"))
  }

  public func updateTrip(tripData: DokoResponsePacket) async {
    if pendingActivity == .trip { return }
    guard case .trip(let activity)? = managedActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.updateTrip: no activity"))
      return
    }
    guard let duration = tripData.duration, let distance = tripData.distance else { return }

    let windSock: WindSock? = if let course = tripData.position?.course, let weather = tripData.weather {
      WindSock(
        course: course,
        temperature: weather.temperature,
        conditions: weather.conditionSymbol,
        windSpeed: weather.windSpeed,
        windDirection: weather.windDirection,
        windCompassDirection: weather.windCompassDirection
      )
    } else { nil }
    
    let state = TripActivityAttributes.ContentState(
      tripState: .active,
      duration: .seconds(duration),
      distance: distance,
      efficiency: tripData.tripEfficiency,
      elevation: tripData.position?.elevation,
      rangeConsumed: tripData.batteryDistanceToEmpty,
      windSock: windSock
    )

    @Dependency(\.date.now) var now
    let staleAfter: TimeInterval = 60
    let content = ActivityContent(state: state, staleDate: now.addingTimeInterval(staleAfter))
    await activity.update(content)
    DokoLogging.shared.postLoggingResponse(.liveActivity(".updateTrip"))
  }

  public func endTrip(tripEnd: DokoResponsePacket) async {
    if pendingActivity == .trip { return }
    guard case .trip(let activity)? = managedActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.endTrip: no activity"))
      return
    }
    guard let duration = tripEnd.duration, let distance = tripEnd.distance else { return }

    let state = TripActivityAttributes.ContentState(
      tripState: .ended,
      duration: .seconds(duration),
      distance: distance,
      energy: tripEnd.batteryEnergy.map { $0 },
      rangeConsumed: tripEnd.batteryDistanceToEmpty.map { $0 },
    )
    
    @Dependency(\.date.now) var now
    let staleAfter: TimeInterval = 5
    self.managedActivity = nil
    self.pendingActivity = nil
    await activity.update(ActivityContent(state: state, staleDate: now.addingTimeInterval(staleAfter)))
    DokoLogging.shared.postLoggingResponse(.liveActivity(".endTrip"))
    Task {
      try? await Task.sleep(for: .seconds(5))
      await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .after(now.addingTimeInterval(staleAfter)))
    }
  }

  public func startCharge() async {
    @Dependency(\.date.now) var now
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startCharge: Live Activities not enabled"))
      return
    }
    guard UIApplication.shared.applicationState == .active else {
      DokoLogging.shared.postLoggingResponse(.liveActivity("pending charge live activities (background)"))
      pendingActivity = .charge
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
        content: ActivityContent(state: initial, staleDate: now.addingTimeInterval(15))
      )
    } catch {
      DokoLogging.shared.postLoggingResponse(.liveActivity("pending charge live activities"))
      pendingActivity = .charge
      return
    }
    self.managedActivity = .charge(activity)
    DokoLogging.shared.postLoggingResponse(.liveActivity(".startCharge"))
  }

  public func updateCharge(chargeData: DokoResponsePacket) async {
    if pendingActivity == .charge { return }
    guard case .charge(let activity)? = managedActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.updateCharge: no activity"))
      return
    }
    guard let duration = chargeData.duration else { return }

    let state = ChargeActivityAttributes.ContentState(
      chargeState: .active,
      duration: .seconds(duration),
      stateOfCharge: chargeData.batteryStateOfCharge,
      rangeAdded: nil,
      measuredPower: chargeData.batteryPower.map { $0 },
      batteryVoltage: chargeData.batteryVoltage.map { $0 },
      batteryCurrent: chargeData.batteryCurrent.map { $0 },
      batteryTemperature: chargeData.batteryTemperature.map { $0 },
      couplerTemperature: chargeData.couplerTemperature.map { $0 },
    )

    @Dependency(\.date.now) var now
    let staleAfter: TimeInterval = 60
    let content = ActivityContent(state: state, staleDate: now.addingTimeInterval(staleAfter))
    await activity.update(content)
    DokoLogging.shared.postLoggingResponse(.liveActivity(".updateCharge"))
  }

  public func endCharge(chargeData: DokoResponsePacket) async {
    if pendingActivity == .charge { pendingActivity = nil; return }
    guard case .charge(let activity)? = managedActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.endCharge: no activity"))
      return
    }
    guard let duration = chargeData.duration else { return }

    let state = ChargeActivityAttributes.ContentState(
      chargeState: .active,
      duration: .seconds(duration),
      stateOfCharge: chargeData.batteryStateOfCharge,
      rangeAdded: nil,
      measuredPower: chargeData.batteryPower.map { $0 },
      batteryVoltage: chargeData.batteryVoltage.map { $0 },
      batteryCurrent: chargeData.batteryCurrent.map { $0 },
      batteryTemperature: chargeData.batteryTemperature.map { $0 },
      couplerTemperature: chargeData.couplerTemperature.map { $0 },
    )
    
    @Dependency(\.date.now) var now
    let staleAfter: TimeInterval = 60
    self.managedActivity = nil
    self.pendingActivity = nil
    let endedState = ChargeActivityAttributes.ContentState(chargeState: .ended)
    await activity.update(ActivityContent(state: state, staleDate: now.addingTimeInterval(staleAfter)))
    DokoLogging.shared.postLoggingResponse(.liveActivity(".endCharge"))
    Task {
      try? await Task.sleep(for: .seconds(30))
      await activity.end(ActivityContent(state: endedState, staleDate: nil), dismissalPolicy: .after(now.addingTimeInterval(staleAfter)))
    }
  }

  // MARK: - Push-to-start

  private func pushToStartTrip(token: Data) async {
    let tokenString = token.map { String(format: "%02x", $0) }.joined()
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    let msg = "pushToStartTrip token=\(tokenString.prefix(8))… bundle=\(bundleId)"
    logger.info("\(msg)")
    DokoLogging.shared.postLoggingResponse(.liveActivity(msg))
    #if DEBUG
    let apnsEnvironment = "development"
    #else
    let apnsEnvironment = "production"
    #endif
    let body: [String: String] = [
      "pushToken": tokenString,
      "bundleId": bundleId,
      "apnsEnvironment": apnsEnvironment
    ]
    await sendWorkerRequest(path: "trip-start", body: body)
  }

  private func sendWorkerRequest(path: String, body: [String: String]) async {
    let base = Bundle.main.object(forInfoDictionaryKey: "WorkerBaseURL") as? String ?? ""
    guard let url = URL(string: "\(base)/\(path)") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONEncoder().encode(body)
    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      let status = (response as? HTTPURLResponse)?.statusCode ?? 0
      let responseBody = String(data: data, encoding: .utf8) ?? ""
      let msg = "Worker /\(path): \(status) \(responseBody)"
      logger.info("\(msg)")
      DokoLogging.shared.postLoggingResponse(.liveActivity(msg))
    } catch {
      let msg = "Worker /\(path): \(error)"
      logger.error("\(msg)")
      DokoLogging.shared.postLoggingResponse(.error(msg))
    }
  }
}
