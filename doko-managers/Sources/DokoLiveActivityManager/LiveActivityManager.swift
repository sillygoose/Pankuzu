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

  let startActivityStaleDate: Double = 5
  let endActivityStaleDate: Double = 15

  private init() {
    endOrphanedActivities()
    startAccessoryNameObservation()
    startForegroundObservation()
    startPushToStartTokenObservation()
  }

  // MARK: - Managed Activities

  private var managedTripWindSock: Activity<TripWindSockActivityAttributes>?
  private var managedTripElevation: Activity<TripElevationActivityAttributes>?
  private var managedTripEfficiency: Activity<TripEfficiencyActivityAttributes>?
  private var managedCharge: Activity<ChargeSessionActivityAttributes>?

  private var hasAnyTripActivity: Bool { managedTripWindSock != nil || managedTripElevation != nil || managedTripEfficiency != nil }
  private var hasAnyManagedActivity: Bool { hasAnyTripActivity || managedCharge != nil }

  // MARK: - Push-to-Start Tokens

  private var tripWindSockPushToStartToken: Data?
  private var tripElevationPushToStartToken: Data?
  private var tripEfficiencyPushToStartToken: Data?
  private var chargePushToStartToken: Data?

  // MARK: - Pending

  private enum PendingActivity { case trip, charge }
  private var pendingActivity: PendingActivity?

  // MARK: - Init Helpers

  private func endOrphanedActivities() {
    Task {
      for activity in Activity<TripWindSockActivityAttributes>.activities {
        let final = TripWindSockActivityAttributes.ContentState(tripState: .ended)
        await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
        DokoLogging.shared.postLoggingResponse(.liveActivity("ended orphaned tripWindSock activity \(activity.id)"))
      }
      for activity in Activity<TripElevationActivityAttributes>.activities {
        let final = TripElevationActivityAttributes.ContentState(tripState: .ended)
        await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
        DokoLogging.shared.postLoggingResponse(.liveActivity("ended orphaned tripElevation activity \(activity.id)"))
      }
      for activity in Activity<TripEfficiencyActivityAttributes>.activities {
        let final = TripEfficiencyActivityAttributes.ContentState(tripState: .ended)
        await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
        DokoLogging.shared.postLoggingResponse(.liveActivity("ended orphaned tripEfficiency activity \(activity.id)"))
      }
      for activity in Activity<ChargeSessionActivityAttributes>.activities {
        let final = ChargeSessionActivityAttributes.ContentState(chargeState: .ended)
        await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
        DokoLogging.shared.postLoggingResponse(.liveActivity("ended orphaned charge activity \(activity.id)"))
      }
    }
  }

  private func endAllActivitiesImmediately() async {
    if let activity = managedTripWindSock {
      let final = TripWindSockActivityAttributes.ContentState(tripState: .ended)
      await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
      managedTripWindSock = nil
    }
    if let activity = managedTripElevation {
      let final = TripElevationActivityAttributes.ContentState(tripState: .ended)
      await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
      managedTripElevation = nil
    }
    if let activity = managedTripEfficiency {
      let final = TripEfficiencyActivityAttributes.ContentState(tripState: .ended)
      await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
      managedTripEfficiency = nil
    }
    if let activity = managedCharge {
      let final = ChargeSessionActivityAttributes.ContentState(chargeState: .ended)
      await activity.end(ActivityContent(state: final, staleDate: nil), dismissalPolicy: .immediate)
      managedCharge = nil
    }
    pendingActivity = nil
  }

  private func startPushToStartTokenObservation() {
    Task {
      for await token in Activity<TripWindSockActivityAttributes>.pushToStartTokenUpdates {
        tripWindSockPushToStartToken = token
        DokoLogging.shared.postLoggingResponse(.liveActivity("tripWindSockPushToStartToken updated"))
      }
    }
    Task {
      for await token in Activity<TripElevationActivityAttributes>.pushToStartTokenUpdates {
        tripElevationPushToStartToken = token
        DokoLogging.shared.postLoggingResponse(.liveActivity("tripElevationPushToStartToken updated"))
      }
    }
    Task {
      for await token in Activity<TripEfficiencyActivityAttributes>.pushToStartTokenUpdates {
        tripEfficiencyPushToStartToken = token
        DokoLogging.shared.postLoggingResponse(.liveActivity("tripEfficiencyPushToStartToken updated"))
      }
    }
    Task {
      for await token in Activity<ChargeSessionActivityAttributes>.pushToStartTokenUpdates {
        chargePushToStartToken = token
        DokoLogging.shared.postLoggingResponse(.liveActivity("chargePushToStartToken updated"))
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
          guard self.hasAnyManagedActivity else { continue }
          DokoLogging.shared.postLoggingResponse(.liveActivity("ending activities due to disconnect"))
          await self.endAllActivitiesImmediately()
        }
        oldAccessoryName = newAccessoryName
      }
    }
  }

  // MARK: - Trip

  public func startTrip() async {
    @Dependency(\.date.now) var now
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip: Live Activities not enabled"))
      return
    }
    if hasAnyManagedActivity {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip: already managing an activity"))
      await endAllActivitiesImmediately()
    }

    let hasActiveScene = UIApplication.shared.connectedScenes
      .contains { $0.activationState == .foregroundActive }

    if !hasActiveScene {
      if let token = tripWindSockPushToStartToken {
        await pushToStartTripWindSock(token: token)
        Task {
          for await activity in Activity<TripWindSockActivityAttributes>.activityUpdates {
            guard self.managedTripWindSock == nil else { break }
            self.managedTripWindSock = activity
            self.pendingActivity = nil
            DokoLogging.shared.postLoggingResponse(.liveActivity(".startTrip windSock via push-to-start"))
            break
          }
        }
      }
      if let token = tripElevationPushToStartToken {
        await pushToStartTripElevation(token: token)
        Task {
          for await activity in Activity<TripElevationActivityAttributes>.activityUpdates {
            guard self.managedTripElevation == nil else { break }
            self.managedTripElevation = activity
            DokoLogging.shared.postLoggingResponse(.liveActivity(".startTrip elevation via push-to-start"))
            break
          }
        }
      }
      if let token = tripEfficiencyPushToStartToken {
        await pushToStartTripEfficiency(token: token)
        Task {
          for await activity in Activity<TripEfficiencyActivityAttributes>.activityUpdates {
            guard self.managedTripEfficiency == nil else { break }
            self.managedTripEfficiency = activity
            DokoLogging.shared.postLoggingResponse(.liveActivity(".startTrip efficiency via push-to-start"))
            break
          }
        }
      }
      pendingActivity = .trip
      return
    }

    let windSockInitial = TripWindSockActivityAttributes.ContentState(tripState: .starting)
    do {
      managedTripWindSock = try Activity.request(
        attributes: TripWindSockActivityAttributes(),
        content: ActivityContent(state: windSockInitial, staleDate: now.addingTimeInterval(startActivityStaleDate)),
        pushType: .token
      )
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip(windSock) failed: \(error)"))
    }

    let elevationInitial = TripElevationActivityAttributes.ContentState(tripState: .starting)
    do {
      managedTripElevation = try Activity.request(
        attributes: TripElevationActivityAttributes(),
        content: ActivityContent(state: elevationInitial, staleDate: now.addingTimeInterval(startActivityStaleDate)),
        pushType: .token
      )
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startTrip(elevation) failed: \(error)"))
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

    DokoLogging.shared.postLoggingResponse(.liveActivity(".startTrip"))
  }

  public func updateTrip(tripData: DokoResponsePacket) async {
    if pendingActivity == .trip { return }
    guard hasAnyTripActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.updateTrip: no activity"))
      return
    }

    let duration = tripData.duration ?? 0
    let distance = tripData.distance ?? 0

    #if DEBUG
    let course = tripData.position?.course ?? 0
    let windSock: WindSock? = if let weather = tripData.weather {
      WindSock(
        course: course,
        temperature: weather.temperature,
        conditions: weather.conditionSymbol,
        windSpeed: weather.windSpeed,
        windDirection: weather.windDirection,
        windCompassDirection: weather.windCompassDirection
      )
    } else {
      nil
    }
    #else
    let windSock: WindSock? = if let course = tripData.position?.course, let weather = tripData.weather {
      WindSock(
        course: course,
        temperature: weather.temperature,
        conditions: weather.conditionSymbol,
        windSpeed: weather.windSpeed,
        windDirection: weather.windDirection,
        windCompassDirection: weather.windCompassDirection
      )
    } else {
      nil
    }
    #endif

    @Dependency(\.date.now) var now
    let staleDate = now.addingTimeInterval(30)

    if let activity = managedTripWindSock {
      let state = TripWindSockActivityAttributes.ContentState(
        tripState: .active,
        duration: .seconds(duration),
        distance: distance,
        efficiency: tripData.tripEfficiency,
        elevation: tripData.position?.elevation,
        rangeConsumed: tripData.batteryDistanceToEmpty,
        windSock: windSock
      )
      await activity.update(ActivityContent(state: state, staleDate: staleDate))
    }

    if let activity = managedTripElevation {
      let state = TripElevationActivityAttributes.ContentState(
        tripState: .active,
        duration: .seconds(duration),
        distance: distance,
        efficiency: tripData.tripEfficiency,
        elevation: tripData.position?.elevation,
        rangeConsumed: tripData.batteryDistanceToEmpty,
        windSock: windSock
      )
      await activity.update(ActivityContent(state: state, staleDate: staleDate))
    }

    if let activity = managedTripEfficiency {
      let state = TripEfficiencyActivityAttributes.ContentState(
        tripState: .active,
        duration: .seconds(duration),
        distance: distance,
        efficiency: tripData.tripEfficiency,
        elevation: tripData.position?.elevation,
        rangeConsumed: tripData.batteryDistanceToEmpty,
        windSock: windSock
      )
      await activity.update(ActivityContent(state: state, staleDate: staleDate))
    }

    DokoLogging.shared.postLoggingResponse(.liveActivity(".updateTrip"))
  }

  public func endTrip(tripEnd: DokoResponsePacket) async {
    if pendingActivity == .trip { pendingActivity = nil; return }
    guard hasAnyTripActivity else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.endTrip: no activity"))
      return
    }
    guard let duration = tripEnd.duration, let distance = tripEnd.distance else { return }

    @Dependency(\.date.now) var now

    let windSockToEnd = managedTripWindSock
    let elevationToEnd = managedTripElevation
    let efficiencyToEnd = managedTripEfficiency
    managedTripWindSock = nil
    managedTripElevation = nil
    managedTripEfficiency = nil
    pendingActivity = nil

    if let activity = windSockToEnd {
      let state = TripWindSockActivityAttributes.ContentState(
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

    if let activity = elevationToEnd {
      let state = TripElevationActivityAttributes.ContentState(
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
      await activity.update(ActivityContent(state: state, staleDate: now.addingTimeInterval(endActivityStaleDate)))
      Task {
        try? await Task.sleep(for: .seconds(endActivityStaleDate))
        await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .after(now))
      }
    }

    DokoLogging.shared.postLoggingResponse(.liveActivity(".endTrip"))
  }

  // MARK: - Charge

  public func startCharge() async {
    @Dependency(\.date.now) var now
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startCharge: Live Activities not enabled"))
      return
    }
    if hasAnyManagedActivity {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startCharge: already managing an activity"))
      await endAllActivitiesImmediately()
    }

    let hasActiveScene = UIApplication.shared.connectedScenes
      .contains { $0.activationState == .foregroundActive }

    if !hasActiveScene, let token = chargePushToStartToken {
      await pushToStartCharge(token: token)
      Task {
        for await activity in Activity<ChargeSessionActivityAttributes>.activityUpdates {
          guard self.managedCharge == nil else { break }
          self.managedCharge = activity
          self.pendingActivity = nil
          DokoLogging.shared.postLoggingResponse(.liveActivity(".startCharge via push-to-start"))
          break
        }
      }
      pendingActivity = .charge
      return
    }

    guard hasActiveScene else {
      DokoLogging.shared.postLoggingResponse(.liveActivity("startCharge: no active scene and no push-to-start token, deferring"))
      pendingActivity = .charge
      return
    }

    let initial = ChargeSessionActivityAttributes.ContentState(chargeState: .starting)
    do {
      managedCharge = try Activity.request(
        attributes: ChargeSessionActivityAttributes(),
        content: ActivityContent(state: initial, staleDate: now.addingTimeInterval(startActivityStaleDate)),
        pushType: .token
      )
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.startCharge failed: \(error)"))
      return
    }
    DokoLogging.shared.postLoggingResponse(.liveActivity(".startCharge"))
  }

  public func updateCharge(chargeData: DokoResponsePacket) async {
    if pendingActivity == .charge { return }
    guard let activity = managedCharge else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.updateCharge: no activity"))
      return
    }
    guard let duration = chargeData.duration else { return }

    let state = ChargeSessionActivityAttributes.ContentState(
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
    await activity.update(ActivityContent(state: state, staleDate: now.addingTimeInterval(60)))
    DokoLogging.shared.postLoggingResponse(.liveActivity(".updateCharge"))
  }

  public func endCharge(chargeData: DokoResponsePacket) async {
    if pendingActivity == .charge { pendingActivity = nil; return }
    guard let activity = managedCharge else {
      DokoLogging.shared.postLoggingResponse(.error("LiveActivityManager.endCharge: no activity"))
      return
    }
    guard let duration = chargeData.duration else { return }

    let state = ChargeSessionActivityAttributes.ContentState(
      chargeState: .ended,
      duration: .seconds(duration),
      stateOfCharge: chargeData.batteryStateOfCharge,
      energy: chargeData.batteryEnergy,
      rangeAdded: chargeData.batteryDistanceToEmpty,
      batteryTemperature: chargeData.batteryTemperature,
    )

    @Dependency(\.date.now) var now
    managedCharge = nil
    pendingActivity = nil
    let endedState = ChargeSessionActivityAttributes.ContentState(chargeState: .ended)
    await activity.update(ActivityContent(state: state, staleDate: now.addingTimeInterval(endActivityStaleDate)))
    DokoLogging.shared.postLoggingResponse(.liveActivity(".endCharge"))
    Task {
      try? await Task.sleep(for: .seconds(30))
      await activity.end(ActivityContent(state: endedState, staleDate: nil), dismissalPolicy: .after(now.addingTimeInterval(endActivityStaleDate)))
    }
  }

  // MARK: - Push-to-Start

  private func pushToStartTripWindSock(token: Data) async {
    let tokenString = token.map { String(format: "%02x", $0) }.joined()
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    let msg = "pushToStartTripWindSock token=\(tokenString.prefix(8))… bundle=\(bundleId)"
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

  private func pushToStartTripElevation(token: Data) async {
    let tokenString = token.map { String(format: "%02x", $0) }.joined()
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    let msg = "pushToStartTripElevation token=\(tokenString.prefix(8))… bundle=\(bundleId)"
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
    await sendWorkerRequest(path: "trip-elevation-start", body: body)
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
    await sendWorkerRequest(path: "charge-start", body: body)
  }

  private func sendWorkerRequest(path: String, body: [String: String]) async {
    let base = Bundle.main.object(forInfoDictionaryKey: "WorkerBaseURL") as? String ?? ""
    logger.info("WorkerBaseURL: '\(base)'")
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
