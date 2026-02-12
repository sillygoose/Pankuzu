import SwiftUI

public struct DokoGridLocation: View {
  let color: Color
  let placeName: String
  let cityState: String
  let label: String
  let iconName: String
  let action: () -> Void

  public init(color: Color, placeName: String, cityState: String, label: String, iconName: String, action: @escaping () -> Void) {
    self.color = color
    self.placeName = placeName
    self.cityState = cityState
    self.label = label
    self.iconName = iconName
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack {
        VStack(alignment: .center) {
          Image(systemName: iconName)
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
        .foregroundStyle(DesignTokens.Color.label)
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
            iconName: "mappin.and.ellipse.circle.fill"
          ) {
          }
        }
      }

      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          DokoGridLocation(
            color: .blue,
            placeName: "In Progress",
            cityState: "",
            label: "To",
            iconName: "mappin.and.ellipse.circle.fill"
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
