import SwiftUI

public struct GridButton: View {
  let title: String
  let color: Color
  let symbolName: String
  let action: () -> Void
  
  public init(
    color: Color,
    symbolName: String,
    title: String,
    action: @escaping () -> Void
  ) {
    self.color = color
    self.symbolName = symbolName
    self.title = title
    self.action = action
  }
  
  public var body: some View {
    Button(action: action) {
      VStack {
        Image(systemName: symbolName)
          .font(DesignTokens.Font.title)
          .bold()
          .foregroundStyle(color)
          .frame(width: 32, height: 32)
        
        Text(title)
          .lineLimit(1)
          .font(DesignTokens.Font.headline)
          .foregroundStyle(.gray)
          .frame(maxWidth: .infinity, alignment: .center)
      }
    }
    .buttonStyle(.borderless)
    .padding(DesignTokens.Padding.cardInsets)
    .background(DesignTokens.Color.cardBackground)
    .cornerRadius(DesignTokens.CornerRadius.medium)
  }
}

#Preview("Grid Button") {
  NavigationStack {
    ScrollView {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          GridButton(
            color: .blue,
            symbolName: "map",
            title: "Map"
          ) {
            print("Map button pressed")
          }
          GridButton(
            color: .green,
            symbolName: "chart.bar.fill",
            title: "Elevation"
          ) {
            print("Elevation button pressed")
          }
        }
      }
      
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          GridButton(
            color: .red,
            symbolName: "bolt",
            title: "Energy"
          ) {
            print("Energy button pressed")
          }
          GridButton(
            color: .purple,
            symbolName: "chart.bar.fill",
            title: "Power"
          ) {
            print("Power button pressed")
          }
          GridButton(
            color: .gray,
            symbolName: "truck.pickup.side",
            title: "F-150 Lightning"
          ) {
            print("F-150 Lightning button pressed")
          }
        }
      }
    }
    .buttonStyle(.plain)
    .listRowBackground(Color.clear)
    .padding([.leading, .trailing], 10)
    .preferredColorScheme(.dark)
  }
}
