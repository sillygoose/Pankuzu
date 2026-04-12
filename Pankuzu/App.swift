import SwiftUI

import DokoUI
import DokoSchema
import DokoSharing

@MainActor
@Observable
class AppModel {
  enum Tab { case trips, charges, tools, settings }
  var selectedTab: Tab

  init(
    selectedTab: Tab = .trips
  ) {
    self.selectedTab = selectedTab
  }
}

struct AppView: View {
  @Bindable var model: AppModel
  @State var isRecording = true

  var body: some View {
    TabView(selection: $model.selectedTab) {
      TripsView(
        model: TripsModel()
      )
      .tabItem { Label("Trips", systemImage: "car") }
      .tag(AppModel.Tab.trips)
      
      ChargesView(
        model: ChargesModel()
      )
      .tabItem { Label("Charges", systemImage: "bolt.fill") }
      .tag(AppModel.Tab.charges)
      
      ToolsView(
        model: ToolsModel()
      )
      .tabItem { Label("Tools", systemImage: "hammer.circle") }
      .tag(AppModel.Tab.tools)

      SettingsView(
        model: SettingsModel()
      )
      .tabItem { Label("Settings", systemImage: "gear") }
      .tag(AppModel.Tab.settings)
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .preferredColorScheme(.dark)
  }
}

#Preview("Trips") {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  AppView(
    model: AppModel(
      selectedTab: .trips
    )
  )
}

#Preview("Charges") {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  AppView(
    model: AppModel(
      selectedTab: .charges
    )
  )
}

#Preview("Tools") {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  AppView(
    model: AppModel(
      selectedTab: .tools
    )
  )
}

#Preview("Settings") {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  AppView(
    model: AppModel(
      selectedTab: .settings
    )
  )
}
