import SwiftUI

public struct DokoGridButton: View {
  let color: Color
  let iconName: String
  let title: String
  let action: () -> Void

  public init(color: Color, iconName: String, title: String, action: @escaping () -> Void) {
    self.color = color
    self.iconName = iconName
    self.title = title
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      VStack {
        Image(systemName: iconName)
          .font(DesignTokens.Font.title)
          .bold()
          .foregroundStyle(color)

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

public struct DokoGridValueButton: View {
  let color: Color
  let value: String?
  let units: String?
  let iconName: String
  let title: String
  let action: () -> Void

  public init(color: Color, value: String?, units: String?, iconName: String, title: String, action: @escaping () -> Void) {
    self.color = color
    self.value = value
    self.units = units
    self.iconName = iconName
    self.title = title
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      VStack {
        HStack {
          Image(systemName: iconName)
            .font(DesignTokens.Font.title)
            .bold()
            .foregroundStyle(color)
          Spacer()
          if let value {
            Text("\(value)")
              .font(DesignTokens.Font.title)
              .fontDesign(.rounded)
              .bold()
              .foregroundStyle(DesignTokens.Color.label)
          }
        }
        HStack {
          Text(title)
            .lineLimit(1)
            .font(DesignTokens.Font.headline)
            .foregroundStyle(.gray)
          Spacer()
          if let units {
            Text("\(units)")
              .lineLimit(1)
              .font(DesignTokens.Font.headline)
              .foregroundStyle(.gray)
          }
        }
      }
    }
    .buttonStyle(.borderless)
    .padding(DesignTokens.Padding.cardInsets)
    .background(DesignTokens.Color.cardBackground)
    .cornerRadius(DesignTokens.CornerRadius.medium)
  }
}

#Preview("DokoGridButton") {
  NavigationStack {
    ScrollView {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          DokoGridValueButton(
            color: .blue,
            value: "3210",
            units: "mi",
            iconName: "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath",
            title: "Route"
          ) {
            print("Route button pressed")
          }
          DokoGridValueButton(
            color: .yellow,
            value: "123",
            units: nil,
            iconName: "car",
            title: "F-150 Lightning"
          ) {
            print("F-150 Lightning button pressed")
          }
        }
      }

      Spacer(minLength: 70)

      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          DokoGridButton(
            color: .blue,
            iconName: "map",
            title: "Map"
          ) {
            print("Map button pressed")
          }
          DokoGridButton(
            color: .green,
            iconName: "chart.bar.fill",
            title: "Elevation"
          ) {
            print("Elevation button pressed")
          }
        }
      }

      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          DokoGridButton(
            color: .red,
            iconName: "bolt",
            title: "Energy"
          ) {
            print("Energy button pressed")
          }
          DokoGridButton(
            color: .purple,
            iconName: "chart.bar.fill",
            title: "Power"
          ) {
            print("Power button pressed")
          }
          DokoGridButton(
            color: .gray,
            iconName: "truck.pickup.side",
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
