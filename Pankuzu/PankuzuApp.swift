import SwiftUI
import BackgroundTasks
import UserNotifications
import CoreLocation
import TipKit

import CoreLocationManager
import DokoSharing
import DokoSchema
import ObdLinkManager
import DokoPacketManager
import DokoVehicleManager
import DokoNotificationManager
import DokoWeatherManager
import DokoLocationManager
import DokoStateEngine
import DokoLiveActivityManager

/*
 NB: Only one refresh task permitted
 Debugging trigger:
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.unchan.pankuzu.daily-pruning"]
 */

private let dbPruningTaskIdentifier: String = "com.unchan.pankuzu.daily-pruning"

func scheduleDatabasePruning() {
  #if !targetEnvironment(simulator)
  withErrorReporting {
    let request = BGProcessingTaskRequest(identifier: dbPruningTaskIdentifier)
    let calendar = Calendar.current
    let tomorrowMidnight = calendar.startOfDay(
      for: calendar.date( byAdding: .day, value: 1, to: Date())!
    )
    let afterMidnight = calendar.date(byAdding: .minute, value: 1, to: tomorrowMidnight)!
    request.earliestBeginDate = afterMidnight
    try BGTaskScheduler.shared.submit(request)
  }
  #endif
}

@main
struct PankuzuApp: App {
  @Environment(\.scenePhase) private var phase
  @Dependency(\.context) var context
  
  static let model = AppModel()
  var locationManager = CoreLocationManager()

  init() {
    if context == .live {
      prepareDependencies {
        $0.defaultDatabase = try! appDatabase()
      }
    }
  }

  var body: some Scene {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    WindowGroup {
      if context == .live {
        AppView(model: Self.model)
          .task {
            try? Tips.configure([
              .displayFrequency(.immediate),
              .datastoreLocation(.applicationDefault)
            ])
            _ = await DokoNotificationManager.shared.requestAuthorization()
            _ = await locationManager.requestUserAuthorization()
            _ = LiveActivityManager.shared
            _ = DokoVehicleManager.shared
            _ = DokoLocationManager.shared
            _ = ObdLinkManager.shared
            _ = await DokoPacketManager.shared
            _ = await DokoWeatherManager.shared
            _ = await DokoStateEngine.shared
            ObdLinkManager.shared.connect()
          }
      }
    }
    .onChange(of: phase) { _, newPhase in
      switch newPhase {
      case .active:
        break
      default:
        break
      }
    }
    .backgroundTask(.appRefresh(dbPruningTaskIdentifier)) {
      @Dependency(\.defaultDatabase) var database
      @Shared(.deletedRecordRetentionDays) var deletedRecordRetentionDays
      scheduleDatabasePruning()
      withErrorReporting {
        try database.write { db in
          try Trip
            .where { $0.readyForDeletion(days: deletedRecordRetentionDays) }
            .delete()
            .execute(db)
        }
      }
      withErrorReporting {
        try database.write { db in
          try Charge
            .where { $0.readyForDeletion(days: deletedRecordRetentionDays) }
            .delete()
            .execute(db)
        }
      }
    }

  }
}
