import UserNotifications
import UIKit
import OSLog

import DokoLogging

public extension Notification.Name {
  static let pankuzuOpenTrips    = Notification.Name("com.unchan.pankuzu.openTrips")
  static let pankuzuOpenCharges  = Notification.Name("com.unchan.pankuzu.openCharges")
  static let pankuzuOpenTools    = Notification.Name("com.unchan.pankuzu.openTools")
  static let pankuzuOpenSettings = Notification.Name("com.unchan.pankuzu.openSettings")
}

public final class DokoNotificationManager: NSObject, Sendable {
  let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: DokoNotificationManager.self)
  )
  
  public static let shared = DokoNotificationManager()

  private override init() {}

  private enum CategoryID {
    static let trips    = "com.unchan.pankuzu.trips"
    static let charges  = "com.unchan.pankuzu.charges"
    static let settings = "com.unchan.pankuzu.settings"
    static let location = "com.unchan.pankuzu.location"
  }

  private func registerCategories() {
    let options: UNNotificationCategoryOptions = [.allowInCarPlay]
    let categories: Set<UNNotificationCategory> = [
      UNNotificationCategory(identifier: CategoryID.trips,    actions: [], intentIdentifiers: [], options: options),
      UNNotificationCategory(identifier: CategoryID.charges,  actions: [], intentIdentifiers: [], options: options),
      UNNotificationCategory(identifier: CategoryID.settings, actions: [], intentIdentifiers: [], options: options),
      UNNotificationCategory(identifier: CategoryID.location, actions: [], intentIdentifiers: [], options: options),
    ]
    UNUserNotificationCenter.current().setNotificationCategories(categories)
  }

  public func requestAuthorization() async -> Bool {
    registerCategories()
    do {
      let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .carPlay])
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
  
  public func locationPermissionNotification() async {
    let content = UNMutableNotificationContent()
    content.title = "Location Permission Error"
    content.body = "Location permission must be Always in order to use background mode."
    content.sound = .default
    content.categoryIdentifier = CategoryID.location
    content.userInfo = ["destination": "locationSettings"]
    await sendNotification(content: content)
  }

  public func accessoryConnectedNotification(accessoryName: String) async {
    let content = UNMutableNotificationContent()
    content.title = "Scan Tool Connected"
    content.body = "Connected to the \(accessoryName) scan tool."
    content.sound = .default
    content.categoryIdentifier = CategoryID.settings
    content.userInfo = ["destination": "settings"]
    await sendNotification(content: content)
  }

  public func accessoryDisconnectedNotification(accessoryName: String) async {
    let content = UNMutableNotificationContent()
    content.title = "Scan Tool Disconnected"
    content.body = "No longer connected to the \(accessoryName) scan tool."
    content.sound = .default
    content.categoryIdentifier = CategoryID.settings
    content.userInfo = ["destination": "settings"]
    await sendNotification(content: content)
  }

  public func unsupportedVehicleNotification() async {
    let content = UNMutableNotificationContent()
    content.title = "Unsupported Vehicle"
    content.body = "Connected to an unsupported vehicle, disconnecting."
    content.sound = .default
    content.categoryIdentifier = CategoryID.settings
    content.userInfo = ["destination": "settings"]
    await sendNotification(content: content)
  }

  public func startTripNotification(vehicle: String) async {
    let content = UNMutableNotificationContent()
    content.title = "Starting New Trip"
    content.body = "Starting a trip in your \(vehicle), tap to show Live Activities."
    content.sound = .default
    content.categoryIdentifier = CategoryID.trips
    content.userInfo = ["destination": "trips"]
    await sendNotification(content: content)
  }

  public func startChargeNotification(vehicle: String) async {
    let content = UNMutableNotificationContent()
    content.title = "Starting New Charge"
    content.body = "Starting a charge in your \(vehicle), tap to show Live Activities."
    content.sound = .default
    content.categoryIdentifier = CategoryID.charges
    content.userInfo = ["destination": "charges"]
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

  nonisolated public func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    switch userInfo["destination"] as? String {
    case "trips":    NotificationCenter.default.post(name: .pankuzuOpenTrips,    object: nil)
    case "charges":  NotificationCenter.default.post(name: .pankuzuOpenCharges,  object: nil)
    case "settings": NotificationCenter.default.post(name: .pankuzuOpenSettings, object: nil)
    case "locationSettings":
      if let url = URL(string: UIApplication.openSettingsURLString) {
        Task { @MainActor in UIApplication.shared.open(url) }
      }
    default: break
    }
    completionHandler()
  }
}
