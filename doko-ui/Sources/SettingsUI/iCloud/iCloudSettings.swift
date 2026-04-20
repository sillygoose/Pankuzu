import SwiftUI
import Dependencies

import CommonUI
import DokoSharing
import DokoLogging

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var iCloudSyncExpanded: Self {
    Self[.appStorage("iCloudSettings-iCloudSyncExpanded"), default: true]
  }
}

@MainActor
@Observable
class iCloudSettingsModel {
  @ObservationIgnored @Shared(.appSettings) var appSettings

  func iCloudSyncToggleChanged(isOn: Bool) async {
    @Dependency(\.defaultSyncEngine) var syncEngine
    $appSettings.iCloudSync.withLock { $0 = isOn }

    if appSettings.iCloudSync {
      do {
        try await syncEngine.start()
        DokoLogging.shared.postLoggingResponse(.iCloud("sync started"))
      } catch {
        DokoLogging.shared.postLoggingResponse(.error("\(String(describing: error))"))
      }
    } else {
      syncEngine.stop()
      DokoLogging.shared.postLoggingResponse(.iCloud("sync stopped"))
    }
  }
}

struct iCloudSettingsView: View {
  @Bindable var model: iCloudSettingsModel

  @Shared(.iCloudSyncExpanded) var iCloudSyncExpanded

  var body: some View {
    List {
      Section {
        Toggle(
          "iCloud Sync",
          isOn: Binding(
            get: { model.appSettings.iCloudSync },
            set: { isOn, _ in
              Task { await model.iCloudSyncToggleChanged(isOn: isOn) }
            }
          )
        )
        #if !DEBUG
        .disabled(true)
        #endif
      } footer: {
        Text("iCloud Sync will share your trips, charges, and settings across all your devices signed into the same iCloud account. This feature is currently in early beta so keep current backups of your data in case you need to restore from a backup.")
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("iCloud")
  }
}

#Preview {
  NavigationStack {
    iCloudSettingsView(
      model: iCloudSettingsModel()
    )
    .preferredColorScheme(.dark)
  }
}
