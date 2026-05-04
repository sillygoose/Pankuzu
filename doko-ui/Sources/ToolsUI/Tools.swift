import SwiftUI
import TipKit

import CommonUI
import ChargesUI
import DokoSharing

@MainActor @Observable public final class ToolsModel {
  public init() {}
}

public struct ToolsView: View {
  @Bindable var model: ToolsModel

  @State private var isAddingCharge = false
  @State private var path = NavigationPath()

  public init(model: ToolsModel) {
    self.model = model
  }

  public var body: some View {
    NavigationStack(path: $path) {
      TipView(ToolsAddChargeTip())
      List {
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
          GridButton(
            color: .green,
            symbolName: "ev.charger",
            title: "Add Charge"
          ) {
            isAddingCharge = true
          }

          GridButton(
            color: .mint,
            symbolName: "chart.bar.fill",
            title: "Charge History"
          ) {
            path.append(Destination.chargeHistory)
          }

          GridButton(
            color: .green,
            symbolName: "chart.line.uptrend.xyaxis",
            title: "Trip Efficiency"
          ) {
            path.append(Destination.tripEfficiency)
          }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
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
      .navigationDestination(for: Destination.self) { destination in
        switch destination {
        case .chargeHistory:
          ChargeHistoryChartView()
        case .tripEfficiency:
          TripEfficiencyChartView()
        }
      }
    }
  }

  enum Destination: Hashable {
    case chargeHistory
    case tripEfficiency
  }
}

#Preview {
  NavigationStack {
    let _ = try? Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.applicationDefault)])
    ToolsView(
      model: ToolsModel()
    )
    .preferredColorScheme(.dark)
  }
}
