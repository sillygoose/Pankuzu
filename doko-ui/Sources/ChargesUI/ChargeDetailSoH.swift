import SwiftUI

import DokoSchema
import CommonUI

#Preview {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  @FetchAll var charges: [Charge]
  NavigationStack {
    ChargeDetailView(
      model: ChargeDetailModel(
        destination: .stateOfHealthChart,
        chargeID: charges.first!.id
      )
    )
    .preferredColorScheme(.dark)
  }
}
