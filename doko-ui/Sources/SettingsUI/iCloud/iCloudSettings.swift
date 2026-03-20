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
  @ObservationIgnored @Shared(.iCloudSync) var iCloudSync

  func iCloudSyncToggleChanged(isOn: Bool) async {
    @Dependency(\.defaultSyncEngine) var syncEngine
    $iCloudSync.withLock { $0 = isOn }

    if iCloudSync {
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
      DisclosureGroup(
        isExpanded: Binding(
          get: { iCloudSyncExpanded },
          set: { newValue in $iCloudSyncExpanded.withLock { $0 = newValue } }
        )
      ) {
        Toggle(
          "Enable iCloud Sync",
          isOn: Binding(
            get: { model.iCloudSync },
            set: { isOn, _ in
              Task { await model.iCloudSyncToggleChanged(isOn: isOn) }
            }
          )
        )
      } label: {
        Text("iCloud Sync")
      }
    }
    .listStyle(.plain)
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
