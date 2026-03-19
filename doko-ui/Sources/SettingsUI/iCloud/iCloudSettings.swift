import SwiftUI
import Dependencies

import CommonUI
import DokoSharing

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var iCloudSyncExpanded: Self {
    Self[.appStorage("iCloudSettings-iCloudSyncExpanded"), default: true]
  }
}

@MainActor
@Observable
class iCloudSettingsModel {
  @ObservationIgnored @Shared(.iCloudSync) var iCloudSync

  func iCloudSyncToggleChanged(isOn: Bool) {
    $iCloudSync.withLock { $0 = isOn }
//    let _ = prepareDependencies {
//      try! $0.iCloudSyncDatabase()
//    }
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
            set: { isOn, _ in model.iCloudSyncToggleChanged(isOn: isOn) }
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
