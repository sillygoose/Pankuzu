import Foundation
import UIKit
import UserNotifications
import CarPlay

import PushNotifications

import CoreLocationManager
import DokoNotificationManager
import DokoLogging

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    if connectingSceneSession.role == .carTemplateApplication {
      let config = UISceneConfiguration(name: "CarPlay", sessionRole: connectingSceneSession.role)
      config.sceneClass = CPTemplateApplicationScene.self
      config.delegateClass = CarPlaySceneDelegate.self
      return config
    }
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = DokoNotificationManager.shared

    let locationsHandler = CoreLocationManager.shared
    locationsHandler.restoreBackgroundSession()
    /*
     Bug — line 35: self-assignment no-op
       if locationsHandler.backgroundActivity {
           locationsHandler.backgroundActivity = true  // sets true when already true
       }
       This only sets the property when it's already true, doing nothing. The intent looks like it should restart background
       activity on launch — probably should be locationsHandler.startBackgroundActivity() or unconditionally set, depending
       on what the API expects.
     */

    PushNotifications.shared.start(instanceId: "###")
    PushNotifications.shared.registerForRemoteNotifications()
    return true
  }
  
  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    PushNotifications.shared.registerDeviceToken(deviceToken)
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    DokoLogging.shared.postLoggingResponse(.info("Device token: \(tokenString)"))
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    DokoLogging.shared.postLoggingResponse(.error("Failed to register for notifications: \(error)"))
  }
}
