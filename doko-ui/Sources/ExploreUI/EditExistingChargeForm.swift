import SwiftUI

import ChargesUI
import DokoSchema

@MainActor
@Observable
public final class EditExistingChargeModel {
  @ObservationIgnored @FetchAll var charges: [Charge]

  public init() {
    _charges = FetchAll(
      Charge
        .where { $0.isDeleted.eq(false) }
        .order { $0.timeStart.desc() }
    )
  }
}

public struct EditExistingChargeView: View {
  @Bindable var model: EditExistingChargeModel
  @State private var editingCharge: Charge?

  public init(model: EditExistingChargeModel) {
    self.model = model
  }

  public var body: some View {
    List(model.charges) { charge in
      Button {
        editingCharge = charge
      } label: {
        ChargeRow(charge: charge)
      }
      .buttonStyle(.plain)
    }
    .listStyle(.plain)
    .navigationTitle("Select Charge To edit")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(item: $editingCharge) { charge in
      NavigationStack {
        EditChargeFormView(
          model: EditChargeFormModel(charge: Charge.Draft(charge))
        )
        .navigationTitle("Edit Charge")
        .navigationBarTitleDisplayMode(.inline)
        //.presentationDetents([.medium])
      }
    }
  }
}

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    EditExistingChargeView(model: EditExistingChargeModel())
      .preferredColorScheme(.dark)
  }
}
