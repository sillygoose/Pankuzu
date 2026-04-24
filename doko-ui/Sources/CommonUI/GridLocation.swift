import SwiftUI

public struct DokoGridLocation: View {
  let color: Color
  let placeName: String
  let cityState: String
  let label: String
  let symbolName: String
  let action: () -> Void
  
  public init(color: Color, placeName: String, cityState: String, label: String, symbolName: String, action: @escaping () -> Void) {
    self.color = color
    self.placeName = placeName
    self.cityState = cityState
    self.label = label
    self.symbolName = symbolName
    self.action = action
  }
  
  public var body: some View {
    Button(action: action) {
      HStack(spacing: DesignTokens.Grid.horizontalSpacing) {
        VStack(alignment: .center) {
          Image(systemName: symbolName)
            .font(DesignTokens.Font.largeTitle)
            .bold()
            .foregroundStyle(color)
          Text(label)
            .font(DesignTokens.Font.headline)
            .foregroundStyle(.gray)
        }
        Spacer()
        VStack(alignment: .leading) {
          Text("\(placeName)")
          Text("\(cityState)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fontDesign(.rounded)
        .foregroundStyle(DesignTokens.Color.value)
      }
    }
    .buttonStyle(.borderless)
    .padding(DesignTokens.Padding.cardInsetsWide)
    .background(DesignTokens.Color.secondaryGroupedBackground)
    .cornerRadius(DesignTokens.CornerRadius.medium)
  }
}

#Preview("DokoGridLocation") {
  NavigationStack {
    ScrollView {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          DokoGridLocation(
            color: .purple,
            placeName: "Bob's Barbeque",
            cityState: "Homer, NY",
            label: "From",
            symbolName: "mappin.and.ellipse.circle.fill"
          ) {
          }
        }
      }
      
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          DokoGridLocation(
            color: .blue,
            placeName: "Kwik-Fill",
            cityState: "7Skaneatekes, NY",
            label: "To",
            symbolName: "mappin.and.ellipse.circle.fill"
          ) {
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
