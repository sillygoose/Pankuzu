import Foundation
import UIKit
import OSLog
@preconcurrency import ActivityKit

import Dependencies
@_exported import DokoDesignTokens
@_exported import DokoExtensions
@_exported import DokoTypes
import DokoLogging
import DokoSharing

@MainActor
public final class LiveActivityManager {
  public static let shared = LiveActivityManager()

  private let logger = Logger(subsystem: "com.unchan.doko", category: "LiveActivityManager")

  let startActivityStaleDate: Double = 5
  let endActivityStaleDate: Double = 15

  private init() {
    endOrphanedActivities()
    startAccessoryNameObservation()
    startForegroundObservation()
    startPushToStartTokenObservation()
    startActivityUpdatesObservation()
  }

  private func endOrphanedActivities() {
    Task {
      for activity in Activity<TripOverviewActivityAttributes>.activities {
        let final = TripOverviewActivityAttributes.ContentState(tripState: .ended)
        let content = ActivityContent(state: final, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        DokoLogging.shared.postLoggingResponse(.liveActivity("ended orphaned tripOverview activity \(activity.id)"))
      }
      for activity in Activity<TripEfficiencyActivityAttributes>.activities {
        let final = TripEfficiencyActivityAttributes.ContentState(tripState: .ended)
        let content = ActivityContent(state: final, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        DokoLogging.shared.postLoggingResponse(.liveActivity("ended orphaned tripEfficiency activity \(activity.id)"))
      }
      for activity in Activity<ChargeOverviewActivityAttributes>.activities {
        let final = ChargeOverviewActivityAttributes.ContentState(chargeState: .ended)
        let content = ActivityContent(state: final, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        DokoLogging.shared.postLoggingResponse(.liveActivity("ended orphaned charge activity \(activity.id)"))
      }
    }
  }

  // A trip is now two simultaneous Live Activities (overview + efficiency chart), so a single
  // "managed activity" slot no longer fits — each gets its own optional, and `hasAnyTripActivity`
  // stands in for what used to be a single non-nil check.
  private var managedTripOverview: Activity<TripOverviewActivityAttributes>?
  private var managedTripEfficiency: Activity<TripEfficiencyActivityAttributes>?
  private var managedCharge: Activity<ChargeOverviewActivityAttributes>?

  private var hasAnyTripActivity: Bool { managedTripOverview != nil || managedTripEfficiency != nil }

  private func endTripActivitiesImmediately() async {
    if let activity = managedTripOverview {
      let final = TripOverviewActivityAttributes.ContentState(tripState: .ended)
      await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
      managedTripOverview = nil
    }
    if let activity = managedTripEfficiency {
      let final = TripEfficiencyActivityAttributes.ContentState(tripState: .ended)
      await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
      managedTripEfficiency = nil
    }
  }

  private func endChargeActivityImmediately() async {
    guard let activity = managedCharge else { return }
    let final = ChargeOverviewActivityAttributes.ContentState(chargeState: .ended)
    await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
    managedCharge = nil
  }

  private var tripOverviewPushToStartToken: Data?
  private var tripEfficiencyPushToStartToken: Data?
  private var chargeOvwerviewPushToStartToken: Data?

  private enum PendingActivity {
    case trip
    case charge
  }

  private var pendingActivity: PendingActivity?

  private func startPushToStartTokenObservation() {
    Task {
      for await token in Activity<TripOverviewActivityAttributes>.pushToStartTokenUpdates {
        tripOverviewPushToStartToken = token
        DokoLogging.shared.postLoggingResponse(.liveActivity("tripOverviewPushToStartToken updated"))
      }
    }
    Task {
      for await token in Activity<TripEfficiencyActivityAttributes>.pushToStartTokenUpdates {
        tripEfficiencyPushToStartToken = token
        DokoLogging.shared.postLoggingResponse(.liveActivity("tripEfficiencyPushToStartToken updated"))
      }
    }
    Task {
      for await token in Activity<ChargeOverviewActivityAttributes>.pushToStartTokenUpdates {
        chargeOvwerviewPushToStartToken = token
        DokoLogging.shared.postLoggingResponse(.liveActivity("chargeOverviewPushToStartToken updated"))
      }
    }
  }

  // `tripOverviewPushToStartToken`/etc. are populated by the long-lived Tasks above, but those
  // Tasks are scheduled asynchronously — there's no guarantee they've delivered a value yet by
  // the time startTrip()/startCharge() runs synchronously right after LiveActivityManager is
  // first constructed (e.g. from a background accessory-wake launch). Rather than sampling a
  // possibly-still-nil variable, wait briefly on the live stream itself as a fallback.
  private func resolveTripOverviewPushToStartToken() async -> Data? {
    if let tripOverviewPushToStartToken { return tripOverviewPushToStartToken }
    return await withTaskGroup(of: Data?.self) { group in
      group.addTask {
        for await token in Activity<TripOverviewActivityAttributes>.pushToStartTokenUpdates {
          return token
        }
        return nil
      }
      group.addTask {
        try? await Task.sleep(for: .seconds(2))
        return nil
      }
      let result = await group.next() ?? nil
      group.cancelAll()
      return result
    }
  }

  private func resolveTripEfficiencyPushToStartToken() async -> Data? {
    if let tripEfficiencyPushToStartToken { return tripEfficiencyPushToStartToken }
    return await withTaskGroup(of: Data?.self) { group in
      group.addTask {
        for await token in Activity<TripEfficiencyActivityAttributes>.pushToStartTokenUpdates {
          return token
        }
        return nil
      }
      group.addTask {
        try? await Task.sleep(for: .seconds(2))
        return nil
      }
      let result = await group.next() ?? nil
      group.cancelAll()
      return result
    }
  }

  private func resolveChargeOverviewPushToStartToken() async -> Data? {
    if let chargeOvwerviewPushToStartToken { return chargeOvwerviewPushToStartToken }
    return await withTaskGroup(of: Data?.self) { group in
      group.addTask {
        for await token in Activity<ChargeOverviewActivityAttributes>.pushToStartTokenUpdates {
          return token
        }
        return nil
      }
      group.addTask {
        try? await Task.sleep(for: .seconds(2))
        return nil
      }
      let result = await group.next() ?? nil
      group.cancelAll()
      return result
    }
  }

  // Persistent for the app's lifetime — this is what actually reconciles the managed activities
  // with reality for push-to-start. A push-to-start activity is created by the system (via
  // APNs), possibly while this process is backgrounded or not running at all, so adoption
  // can't rely on a one-shot Task tied to the specific `startTrip()`/`startCharge()` call that
  // triggered the push: that call may have long since been suspended or killed by the time the
  // activity actually appears. Subscribing here, once, for the life of the app guarantees we
  // see it whenever it shows up — including activities that already existed when this process
  // launched, since `activityUpdates` replays current activities to a new subscriber.
  private func startActivityUpdatesObservation() {
    Task {
      for await activity in Activity<TripOverviewActivityAttributes>.activityUpdates {
        switch activity.activityState {
        case .active, .stale:
          if self.managedTripOverview != nil {
            // already tracking one; ignore
          } else if activity.content.state.tripState == .ended {
            // Still technically .active/.stale during endTrip()'s grace window (content already
            // says .ended, but the delayed .end() call hasn't fired yet) — not a new trip to adopt.
          } else {
            self.managedTripOverview = activity
            self.pendingActivity = nil
            DokoLogging.shared.postLoggingResponse(.liveActivity("captured tripOverview via activityUpdates"))
          }
        case .ended, .dismissed:
          if self.managedTripOverview?.id == activity.id {
            self.managedTripOverview = nil
          }
        case .pending:
          break
        @unknown default:
          break
        }
      }
    }
    Task {
      for await activity in Activity<TripEfficiencyActivityAttributes>.activityUpdates {
        switch activity.activityState {
        case .active, .stale:
          if self.managedTripEfficiency != nil {
            // already tracking one; ignore
          } else if activity.content.state.tripState == .ended {
            // Same grace-window guard as above, for the efficiency activity.
          } else {
            self.managedTripEfficiency = activity
            self.pendingActivity = nil
            DokoLogging.shared.postLoggingResponse(.liveActivity("captured tripEfficiency via activityUpdates"))
          }
        case .ended, .dismissed:
          if self.managedTripEfficiency?.id == activity.id {
            self.managedTripEfficiency = nil
          }
        case .pending:
          break
        @unknown default:
          break
        }
      }
    }
    Task {
      for await activity in Activity<ChargeOverviewActivityAttributes>.activityUpdates {
        switch activity.activityState {
        case .active, .stale:
          if self.managedCharge != nil {
            // already tracking one; ignore
          } else if activity.content.state.chargeState == .ended {
            // Still technically .active/.stale during endCharge()'s grace window (content already
            // says .ended, but the delayed .end() call hasn't fired yet) — not a new charge to adopt.
          } else {
            self.managedCharge = activity
            self.pendingActivity = nil
            DokoLogging.shared.postLoggingResponse(.liveActivity("captured charge via activityUpdates"))
          }
        case .ended, .dismissed:
          if self.managedCharge?.id == activity.id {
            self.managedCharge = nil
          }
        case .pending:
          break
        @unknown default:
          break
        }
      }
    }
  }

  private func startForegroundObservation() {
    let names: [Notification.Name] = [UIApplication.didBecomeActiveNotification, UIScene.didActivateNotification]
    for name in names {
      Task {
        for await _ in NotificationCenter.default.notifications(named: name) {
          guard let pending = self.pendingActivity else { continue }
          self.pendingActivity = nil
          switch pending {
          case .trip: await self.startTrip(true)
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
          if self.hasAnyTripActivity || self.managedCharge != nil {
            DokoLogging.shared.postLoggingResponse(.liveActivity("ending activity due to disconnect"))
            await self.endTripActivitiesImmediately()
            await self.endChargeActivityImmediately()
            self.pendingActivity = nil
          } else {
            for activity in Activity<TripOverviewActivityAttributes>.activities {
              let final = TripOverviewActivityAttributes.ContentState(tripState: .ended)
              await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
            }
            for activity in Activity<TripEfficiencyActivityAttributes>.activities {
              let final = TripEfficiencyActivityAttributes.ContentState(tripState: .ended)
              await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
            }
            for activity in Activity<ChargeOverviewActivityAttributes>.activities {
              let final = ChargeOverviewActivityAttributes.ContentState(chargeState: .ended)
              await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
            }
            DokoLogging.shared.postLoggingResponse(.liveActivity("ending orphaned activities due to disconnect"))
            self.pendingActivity = nil
          }
        }
        oldAccessoryName = newAccessoryName
      }
    }
  }

  public func startTrip(_ fromPushToStart: Bool = false) async {
    DokoLogging.shared.postLoggingResponse(.liveActivity(".startTrip(\(fromPushToStart)"))

    @Dependency(\.date.now) var now
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip: Live Activities not enabled"))
      return
    }
    if hasAnyTripActivity {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip: already managing a trip activity"))
      await endTripActivitiesImmediately()
    }
    if managedCharge != nil {
      DokoLogging.shared.postLoggingResponse(.liveActivity("LiveActivityManager.startTrip: ending charge activity before starting trip"))
      await endChargeActivityImmediately()
    }

    let hasActiveScene = UIApplication.shared.connectedScenes.contains { $0.activationState == .foregroundActive }
    if !hasActiveScene {
      if let token = await resolveTripOverviewPushToStartToken() {
        await pushToStartTrip(token: token)
      } else {
        DokoLogging.shared.postLoggingResponse(.liveActivity("startTrip: no tripOverview push-to-start token"))
      }
      if let token = await resolveTripEfficiencyPushToStartToken() {
        await pushToStartTripEfficiency(token: token)
      } else {
        DokoLogging.shared.postLoggingResponse(.liveActivity("startTrip: no tripEfficiency push-to-start token"))
      }
      // Adoption happens in startActivityUpdatesObservation(), which stays subscribed for the
      // app's lifetime and doesn't depend on this call still being alive when the push lands.
      pendingActivity = .trip
      return
    }

    guard hasActiveScene else {
      DokoLogging.shared.postLoggingResponse(.liveActivity("startTrip: no active scene and no push-to-start token, deferring"))
      pendingActivity = .trip
      return
    }

    let overviewInitial = TripOverviewActivityAttributes.ContentState(tripState: .starting)
    do {
      managedTripOverview = try Activity.request(
        attributes: TripOverviewActivityAttributes(),
        content: ActivityContent(state: overviewInitial, staleDate: now.addingTimeInterval(startActivityStaleDate)),
        pushType: .token
      )
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip(overview) failed: \(error)"))
    }

    let efficiencyInitial = TripEfficiencyActivityAttributes.ContentState(tripState: .starting)
    do {
      managedTripEfficiency = try Activity.request(
        attributes: TripEfficiencyActivityAttributes(),
        content: ActivityContent(state: efficiencyInitial, staleDate: now.addingTimeInterval(startActivityStaleDate)),
        pushType: .token
      )
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip(efficiency) failed: \(error)"))
    }
    DokoLogging.shared.postLoggingResponse(.liveActivity(".startTrip completed"))
  }

  public func updateTrip(tripData: DokoResponsePacket) async {
    if pendingActivity == .trip {
      return
    }
    guard hasAnyTripActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.updateTrip: no activity"))
      return
    }
    let duration = tripData.duration ?? 0
    let distance = tripData.distance ?? 0

    @Dependency(\.date.now) var now
    let staleAfter: TimeInterval = 30

    if let activity = managedTripOverview {
      let windSock: WindSock? = {
        guard let weather = tripData.weather else { return nil }
        #if DEBUG
        let course = tripData.position?.course ?? 0
        #else
        guard let course = tripData.position?.course else { return nil }
        #endif
        return WindSock(
          course: course,
          temperature: weather.temperature,
          conditions: weather.conditionSymbol,
          windSpeed: weather.windSpeed,
          windDirection: weather.windDirection,
          windCompassDirection: weather.windCompassDirection
        )
      }()
      let state = TripOverviewActivityAttributes.ContentState(
        tripState: .active,
        duration: .seconds(duration),
        distance: distance,
        efficiency: tripData.tripEfficiency,
        elevation: tripData.position?.elevation,
        rangeConsumed: tripData.batteryDistanceToEmpty,
        windSock: windSock
      )
      await activity.update(ActivityContent(state: state, staleDate: now.addingTimeInterval(staleAfter)))
    }

    if let activity = managedTripEfficiency {
      DokoLogging.shared.postLoggingResponse(.liveActivity(tripData.tripEfficiencyMovingAverage.description), debugPacket: true)
      let state = TripEfficiencyActivityAttributes.ContentState(
        tripState: .active,
        duration: .seconds(duration),
        distance: distance,
        efficiency: tripData.tripEfficiency,
        pastEfficiency: tripData.tripEfficiency15Minute,
        rangeConsumed: tripData.batteryDistanceToEmpty,
        efficiencyMovingAverage: tripData.tripEfficiencyMovingAverage
      )
      await activity.update(ActivityContent(state: state, staleDate: now.addingTimeInterval(staleAfter)))
    }
    DokoLogging.shared.postLoggingResponse(.liveActivity(".updateTrip"))
  }

  public func endTrip(tripEnd: DokoResponsePacket) async {
    if pendingActivity == .trip { return }
    guard hasAnyTripActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.endTrip: no activity"))
      return
    }
    guard let duration = tripEnd.duration, let distance = tripEnd.distance else { return }

    @Dependency(\.date.now) var now
    let overviewToEnd = managedTripOverview
    let efficiencyToEnd = managedTripEfficiency
    managedTripOverview = nil
    managedTripEfficiency = nil
    pendingActivity = nil

    if let activity = overviewToEnd {
      let state = TripOverviewActivityAttributes.ContentState(
        tripState: .ended,
        duration: .seconds(duration),
        distance: distance,
        energy: tripEnd.batteryEnergy.map { $0 },
        efficiency: tripEnd.tripEfficiency,
        rangeConsumed: tripEnd.batteryDistanceToEmpty.map { $0 },
      )
      await activity.update(ActivityContent(state: state, staleDate: now.addingTimeInterval(endActivityStaleDate)))
      Task {
        try? await Task.sleep(for: .seconds(endActivityStaleDate))
        await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .after(now))
      }
    }

    if let activity = efficiencyToEnd {
      let state = TripEfficiencyActivityAttributes.ContentState(
        tripState: .ended,
        duration: .seconds(duration),
        distance: distance,
        energy: tripEnd.batteryEnergy.map { $0 },
        efficiency: tripEnd.tripEfficiency,
        rangeConsumed: tripEnd.batteryDistanceToEmpty.map { $0 },
      )
      await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
    }
    DokoLogging.shared.postLoggingResponse(.liveActivity(".endTrip"))
  }

  public func startCharge() async {
    @Dependency(\.date.now) var now
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startCharge: Live Activities not enabled"))
      return
    }
    if managedCharge != nil {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startCharge: already managing an activity"))
      await endChargeActivityImmediately()
    }
    if hasAnyTripActivity {
      DokoLogging.shared.postLoggingResponse(.liveActivity("LiveActivityManager.startCharge: ending trip activity before starting charge"))
      await endTripActivitiesImmediately()
    }

    let hasActiveScene = UIApplication.shared.connectedScenes
      .contains { $0.activationState == .foregroundActive }

    if !hasActiveScene {
      if let token = await resolveChargeOverviewPushToStartToken() {
        await pushToStartCharge(token: token)
        // Adoption happens in startActivityUpdatesObservation(), which stays subscribed for the
        // app's lifetime and doesn't depend on this call still being alive when the push lands.
        pendingActivity = .charge
        return
      }
      DokoLogging.shared.postLoggingResponse(.liveActivity("startCharge: no active scene and no push-to-start token, deferring"))
      pendingActivity = .charge
      return
    }

    let initial = ChargeOverviewActivityAttributes.ContentState(chargeState: .starting)
    let activity: Activity<ChargeOverviewActivityAttributes>
    do {
      activity = try Activity.request(
        attributes: ChargeOverviewActivityAttributes(),
        content: ActivityContent(state: initial, staleDate: now.addingTimeInterval(startActivityStaleDate)),
        pushType: .token
      )
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startCharge failed: \(error)"))
      return
    }
    self.managedCharge = activity
    DokoLogging.shared.postLoggingResponse(.liveActivity(".startCharge"))
  }

  public func updateCharge(chargeData: DokoResponsePacket) async {
    if pendingActivity == .charge { return }
    guard let activity = managedCharge else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.updateCharge: no activity"))
      return
    }
    guard let duration = chargeData.duration else { return }

    let state = ChargeOverviewActivityAttributes.ContentState(
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
    guard let activity = managedCharge else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.endCharge: no activity"))
      return
    }
    guard let duration = chargeData.duration else { return }

    let state = ChargeOverviewActivityAttributes.ContentState(
      chargeState: .ended,
      duration: .seconds(duration),
      stateOfCharge: chargeData.batteryStateOfCharge,
      energy: chargeData.batteryEnergy,
      rangeAdded: chargeData.batteryDistanceToEmpty,
      batteryTemperature: chargeData.batteryTemperature,
    )

    @Dependency(\.date.now) var now
    self.managedCharge = nil
    self.pendingActivity = nil
    let endedState = ChargeOverviewActivityAttributes.ContentState(chargeState: .ended)
    await activity.update(ActivityContent(state: state, staleDate: now.addingTimeInterval(endActivityStaleDate)))
    DokoLogging.shared.postLoggingResponse(.liveActivity(".endCharge"))
    Task {
      try? await Task.sleep(for: .seconds(30))
      await activity.end(ActivityContent(state: endedState, staleDate: nil), dismissalPolicy: .after(now.addingTimeInterval(endActivityStaleDate)))
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
    await sendWorkerRequest(path: "trip-overview-start", body: body)
  }

  private func pushToStartTripEfficiency(token: Data) async {
    let tokenString = token.map { String(format: "%02x", $0) }.joined()
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    let msg = "pushToStartTripEfficiency token=\(tokenString.prefix(8))… bundle=\(bundleId)"
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
    await sendWorkerRequest(path: "trip-efficiency-start", body: body)
  }

  private func pushToStartCharge(token: Data) async {
    let tokenString = token.map { String(format: "%02x", $0) }.joined()
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    let msg = "pushToStartCharge token=\(tokenString.prefix(8))… bundle=\(bundleId)"
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
    await sendWorkerRequest(path: "charge-overview-start", body: body)
  }

  private func sendWorkerRequest(path: String, body: [String: String]) async {
    #if DEBUG
    let base = Bundle.main.object(forInfoDictionaryKey: "WorkerBaseURLDev") as? String ?? ""
    #else
    let base = Bundle.main.object(forInfoDictionaryKey: "WorkerBaseURL") as? String ?? ""
    #endif
    logger.info("WorkerBaseURL: '\(base)' path: '\(path)'")
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
