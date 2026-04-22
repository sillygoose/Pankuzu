import AppIntents
import DokoNotificationManager

struct OpenTripsIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Trips"
  static let description = IntentDescription("Open the Trips tab in Pankuzu.")
  static let openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    NotificationCenter.default.post(name: .pankuzuOpenTrips, object: nil)
    return .result()
  }
}

struct OpenChargesIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Charges"
  static let description = IntentDescription("Open the Charges tab in Pankuzu.")
  static let openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    NotificationCenter.default.post(name: .pankuzuOpenCharges, object: nil)
    return .result()
  }
}

struct OpenToolsIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Tools"
  static let description = IntentDescription("Open the Tools tab in Pankuzu.")
  static let openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    NotificationCenter.default.post(name: .pankuzuOpenTools, object: nil)
    return .result()
  }
}

struct OpenSettingsIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Settings"
  static let description = IntentDescription("Open the Settings tab in Pankuzu.")
  static let openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    NotificationCenter.default.post(name: .pankuzuOpenSettings, object: nil)
    return .result()
  }
}
