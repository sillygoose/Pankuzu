import SwiftUI

import DokoABRP
import DokoSharing

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var abrpExpanded: Self {
    Self[.appStorage("Integrations-abrpExpanded"), default: true]
  }
}

@MainActor
@Observable
class IntegrationsModel {
  @ObservationIgnored @Shared(.abrpEnabled) var abrpEnabled
  @ObservationIgnored @Shared(.abrpUserToken) var abrpUserToken

  init() {}
}

struct IntegrationsView: View {
  @State private var model = IntegrationsModel()
  @Shared(.abrpExpanded) var abrpExpanded

  private var abrpAPIKey: String {
    Bundle.main.object(forInfoDictionaryKey: "ABRPAPIKey") as? String ?? ""
  }

  var body: some View {
    List {
      if !abrpAPIKey.isEmpty {
        DisclosureGroup(
          isExpanded: Binding(
            get: { abrpExpanded },
            set: { newValue in $abrpExpanded.withLock { $0 = newValue } }
          )
        ) {
          Section {
            Toggle(
              "Enable",
              isOn: Binding(
                get: { model.abrpEnabled },
                set: { isOn, _ in model.$abrpEnabled.withLock { $0 = isOn } }
              )
            )
            HStack {
              TextField(
                "User Token",
                text: Binding(
                  get: { model.abrpUserToken },
                  set: { token in model.$abrpUserToken.withLock { $0 = token } }
                )
              )
              .autocorrectionDisabled()
              .textInputAutocapitalization(.never)
              if !model.abrpUserToken.isEmpty {
                Button {
                  model.$abrpUserToken.withLock { $0 = "" }
                } label: {
                  Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
              }
            }
          } footer: {
            Text(
              "Enter your ABRP user token to stream live telemetry to A Better Route Planner. Find your token in the ABRP app under Settings → Live Data."
            )
          }
        } label: {
          Text("A Better Route Planner")
        }
      }
    }
    .listStyle(.plain)
    .navigationTitle("Integrations")
  }
}

#Preview {
  NavigationStack {
    IntegrationsView()
      .preferredColorScheme(.dark)
  }
}
