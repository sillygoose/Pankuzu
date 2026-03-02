import UserNotifications
import UIKit
import OSLog

import DokoLogging

public final class DokoNotificationManager: NSObject, Sendable {
  let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: DokoNotificationManager.self)
  )
  
  public static let shared = DokoNotificationManager()

  private override init() {}

  public func requestAuthorization() async -> Bool {
    do {
      let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
      if granted {
        await MainActor.run {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
      return granted
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("DokoNotificationManager.requestAuthorization: \(error.localizedDescription)"))
      return false
    }
  }
  
  private func sendNotification(content: UNMutableNotificationContent) async {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    guard settings.authorizationStatus == .authorized else {
      DokoLogging.shared.postLoggingResponse(.error("DokoNotificationManager: not authorized"))
      return
    }
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    do {
      try await UNUserNotificationCenter.current().add(request)
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("DokoNotificationManager: request failed"))
    }
  }
  
  public func accessoryConnectedNotification(accessoryName: String) async {
    let content = UNMutableNotificationContent()
    content.title = "Scan Tool Connected"
    content.body = "Connected to the \(accessoryName) scan tool."
    content.sound = .default
    await sendNotification(content: content)
  }
  
  public func accessoryDisconnectedNotification(accessoryName: String) async {
    let content = UNMutableNotificationContent()
    content.title = "Scan Tool Disconnected"
    content.body = "No longer connected to the \(accessoryName) scan tool."
    content.sound = .default
    await sendNotification(content: content)
  }
  
  public func startTripNotification(vehicle: String) async {
    let content = UNMutableNotificationContent()
    content.title = "Starting New Trip"
    content.body = "Logging a new trip in your \(vehicle), tap to enable Live Activities."
    content.sound = .default
    await sendNotification(content: content)
  }
  
  public func startChargeNotification(vehicle: String) async {
    let content = UNMutableNotificationContent()
    content.title = "Starting New Charge"
    content.body = "Logging a new charge in your \(vehicle), tap to enable Live Activities."
    content.sound = .default
    await sendNotification(content: content)
  }
}

extension DokoNotificationManager: UNUserNotificationCenterDelegate {
  nonisolated public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}
