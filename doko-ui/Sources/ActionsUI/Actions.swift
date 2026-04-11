import SwiftUI
import TipKit

import CommonUI
import ChargesUI
import DokoSharing

@MainActor @Observable public final class ActionsModel {
  public init() {}
}

public struct ActionsView: View {
  @Bindable var model: ActionsModel

  @State private var isAddingCharge = false

  public init(model: ActionsModel) {
    self.model = model
  }

  public var body: some View {
    NavigationStack {
      TipView(ActionAddChargeTip())
      List {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
          GridRow {
            DokoGridButton(
              color: .green,
              symbolName: "ev.charger",
              title: "Add Charge"
            ) {
              isAddingCharge = true
            }
          }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .padding([.leading, .trailing], -20)
      }
      .listStyle(.plain)
      .padding(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
      .sheet(isPresented: $isAddingCharge) {
        NavigationStack {
          AddChargeFormView(
            model: AddChargeFormModel()
          )
          .navigationTitle("Add Charge")
          .navigationBarTitleDisplayMode(.inline)
          .presentationDetents([.large])
        }
      }
      .navigationTitle("Actions")
    }
  }
}

#Preview {
  NavigationStack {
    let _ = try? Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.applicationDefault)])
    ActionsView(
      model: ActionsModel()
    )
    .preferredColorScheme(.dark)
  }
}
