import AppIntents
import DokoSharing

struct EnableBackgroundModeIntent: AppIntent {
  static let title: LocalizedStringResource = "Enable Background Mode"
  static let description = IntentDescription("Enable background Bluetooth connectivity in Pankuzu.")

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
    @Shared(.appSettings) var appSettings
    $appSettings.backgroundMode.withLock { $0 = true }
    return .result(value: true)
  }
}

struct DisableBackgroundModeIntent: AppIntent {
  static let title: LocalizedStringResource = "Disable Background Mode"
  static let description = IntentDescription("Disable background Bluetooth connectivity in Pankuzu.")

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
    @Shared(.appSettings) var appSettings
    $appSettings.backgroundMode.withLock { $0 = false }
    return .result(value: false)
  }
}

struct PankuzuShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: EnableBackgroundModeIntent(),
      phrases: [
        "Enable \(.applicationName) background mode"
      ],
      shortTitle: "Enable Background Mode",
      systemImageName: "bolt"
    )
    AppShortcut(
      intent: DisableBackgroundModeIntent(),
      phrases: [
        "Disable \(.applicationName) background mode"
      ],
      shortTitle: "Disable Background Mode",
      systemImageName: "bolt.slash"
    )
  }
}
