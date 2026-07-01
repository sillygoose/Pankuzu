import SwiftUI
import TipKit

import CommonUI
import ChargesUI
import DokoSharing

@MainActor @Observable public final class ExploreModel {
  public init() {}
}

public struct ExploreView: View {
  @Bindable var model: ExploreModel

  @State private var isAddingCharge = false
  @State private var isShowingStateOfHealth = false
  @State private var path = NavigationPath()

  public init(model: ExploreModel) {
    self.model = model
  }

  public var body: some View {
    NavigationStack(path: $path) {
      List {
        TipView(ExploreTabTip())
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
          GridButton(
            color: .orange,
            symbolName: "ev.charger",
            title: "Add Missing Charge"
          ) {
            isAddingCharge = true
          }

          GridButton(
            color: .blue,
            symbolName: "pencil",
            title: "Edit Existing Charge"
          ) {
            path.append(Destination.editExistingCharge)
          }

          GridButton(
            color: .yellow,
            symbolName: "calendar",
            title: "Charge History"
          ) {
            path.append(Destination.chargeHistory)
          }

          GridButton(
            color: .green,
            symbolName: "leaf.fill",
            title: "Trip Efficiency"
          ) {
            path.append(Destination.tripEfficiency)
          }

          GridButton(
            color: .teal,
            symbolName: "waveform.path.ecg",
            title: "Battery State of Health"
          ) {
            isShowingStateOfHealth = true
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
      .sheet(isPresented: $isShowingStateOfHealth) {
        NavigationStack {
          StateOfHealthExploreView()
        }
        .presentationDetents([.medium])
      }
      .navigationDestination(for: Destination.self) { destination in
        switch destination {
        case .editExistingCharge:
          EditExistingChargeView(model: EditExistingChargeModel())
        case .chargeHistory:
          ChargeHistoryChartView()
        case .tripEfficiency:
          TripEfficiencyChartView()
        }
      }
    }
  }

  enum Destination: Hashable {
    case editExistingCharge
    case chargeHistory
    case tripEfficiency
  }
}

#Preview {
  NavigationStack {
    let _ = try? Tips.configure([.displayFrequency(.immediate), .datastoreLocation(.applicationDefault)])
    ExploreView(
      model: ExploreModel()
    )
    .preferredColorScheme(.dark)
  }
}
