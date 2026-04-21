import SwiftUI

public struct DokoGridButton: View {
  let title: String
  let color: Color
  let symbolName: String
  let action: () -> Void

  public init(color: Color, symbolName: String, title: String, action: @escaping () -> Void) {
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

public struct DokoGridValueButton: View {
  let color: Color
  let value: String?
  let units: String?
  let symbolName: String
  let title: String
  let action: () -> Void

  public init(color: Color, value: String?, units: String?, symbolName: String, title: String, action: @escaping () -> Void) {
    self.color = color
    self.value = value
    self.units = units
    self.symbolName = symbolName
    self.title = title
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      VStack {
        HStack {
          Image(systemName: symbolName)
            .font(DesignTokens.Font.title)
            .bold()
            .foregroundStyle(color)
            .frame(width: 32, height: 32)
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

public struct DokoGridStatusButton: View {
  let leftSymbolTitle: String
  let leftSymbol: String
  let leftSymbolColor: Color
  let centerSymbol: String?
  let centerSymbolColor: Color?
  let centerSymbolTitle: String
  let rightSymbol: String?
  let rightSymbolColor: Color?
  let rightSymbolTitle: String
  let action: () -> Void

  public init(
    leftSymbol: String, leftSymbolColor: Color, leftSymbolTitle: String,
    centerSymbol: String? = nil, centerSymbolColor: Color? = nil, centerSymbolTitle: String,
    rightSymbol: String? = nil, rightSymbolColor: Color? = nil, rightSymbolTitle: String,
    action: @escaping () -> Void
  ) {
    self.leftSymbol = leftSymbol
    self.leftSymbolColor = leftSymbolColor
    self.leftSymbolTitle = leftSymbolTitle
    self.centerSymbol = centerSymbol
    self.centerSymbolColor = centerSymbolColor
    self.centerSymbolTitle = centerSymbolTitle
    self.rightSymbol = rightSymbol
    self.rightSymbolColor = rightSymbolColor
    self.rightSymbolTitle = rightSymbolTitle
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      VStack {
        Text("Scan Tool Status")
          .lineLimit(1)
          .font(DesignTokens.Font.headline)
          .foregroundStyle(.gray)
        HStack(spacing: 0) {
          VStack {
            Image(systemName: leftSymbol)
              .font(DesignTokens.Font.largeTitle)
              .bold()
              .foregroundStyle(leftSymbolColor)
              .frame(width: 32, height: 32)
            Text(leftSymbolTitle)
              .lineLimit(1)
              .font(DesignTokens.Font.headline)
              .foregroundStyle(.gray)
          }
          .frame(maxWidth: .infinity)
          if let centerSymbol, let centerSymbolColor {
            VStack {
              Image(systemName: centerSymbol)
                .font(DesignTokens.Font.largeTitle)
                .bold()
                .foregroundStyle(centerSymbolColor)
                .frame(width: 32, height: 32)
              Text(centerSymbolTitle)
                .lineLimit(1)
                .font(DesignTokens.Font.headline)
                .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)
          }
          VStack {
            if let rightSymbol, let rightSymbolColor {
              Image(systemName: rightSymbol)
                .font(DesignTokens.Font.largeTitle)
                .bold()
                .symbolEffect(.pulse, options: .repeating)
                .foregroundStyle(rightSymbolColor)
                .frame(width: 32, height: 32)
            } else {
              Image(systemName: "square.fill")
                .font(DesignTokens.Font.largeTitle)
                .frame(width: 32, height: 32)
                .opacity(0)
            }
            Text(rightSymbolTitle)
              .lineLimit(1)
              .font(DesignTokens.Font.headline)
              .foregroundStyle(.gray)
          }
          .frame(maxWidth: .infinity)
        }
      }
    }
    .buttonStyle(.borderless)
    .padding(DesignTokens.Padding.cardInsets)
    .background(DesignTokens.Color.cardBackground)
    .cornerRadius(DesignTokens.CornerRadius.medium)
  }
}

public struct DokoGridRangeButton: View {
  let rangeName: String
  let symbolColor: Color
  let symbolName: String
  let startValue: String
  let startUnit: String
  let startColor: Color
  let endValue: String
  let endUnit: String
  let endColor: Color
  let action: () -> Void

  public init(
    rangeName: String = "",
    symbolColor: Color,
    symbolName: String,
    startValue: String, startUnit: String, startColor: Color = .primary,
    endValue: String, endUnit: String, endColor: Color = .primary,
    action: @escaping () -> Void
  ) {
    self.rangeName = rangeName
    self.symbolColor = symbolColor
    self.symbolName = symbolName
    self.startValue = startValue
    self.startUnit = startUnit
    self.startColor = startColor
    self.endValue = endValue
    self.endUnit = endUnit
    self.endColor = endColor
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        VStack(alignment: .leading) {
          Image(systemName: symbolName)
            .font(DesignTokens.Font.title)
            .bold()
            .foregroundStyle(symbolColor)
            .frame(width: 32, height: 32)

          Text(rangeName)
            .font(DesignTokens.Font.headline)
            .bold()
            .foregroundStyle(symbolColor)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: 150, alignment: .leading)
        }

        VStack(alignment: .trailing) {
          Text(startValue)
            .font(DesignTokens.Font.title)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(startColor)
          HStack {
            Text("Start")
              .font(DesignTokens.Font.headline)
              .foregroundStyle(.gray)
            Spacer()
            Text(startUnit)
              .lineLimit(1)
              .font(DesignTokens.Font.headline)
              .bold()
              .foregroundStyle(startColor)
          }
        }

        Spacer()

        VStack(alignment: .trailing) {
          Text(endValue)
            .font(DesignTokens.Font.title)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(endColor)
          HStack {
            Text("End")
              .font(DesignTokens.Font.headline)
              .foregroundStyle(.gray)
            Spacer()
            Text(endUnit)
              .lineLimit(1)
              .font(DesignTokens.Font.headline)
              .bold()
              .foregroundStyle(endColor)
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

#Preview("Range Button") {
  NavigationStack {
    ScrollView {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          let couplerTempStart = Measurement(value: 12, unit: UnitTemperature.celsius)
          let couplerTempEnd = Measurement(value: 60, unit: UnitTemperature.celsius)
          DokoGridRangeButton(
            rangeName: "Coupler Temperature",
            symbolColor: .green,
            symbolName: "ev.plug.dc.nacs",
            startValue: String(format: "%.0f", couplerTempStart.value),
            startUnit: couplerTempStart.unit.symbol,
            startColor: .primary,
            endValue: String(format: "%.0f", couplerTempEnd.value),
            endUnit: couplerTempEnd.unit.symbol,
            endColor: .primary
          ) {}
        }

        GridRow {
          let batteryTempStart = Measurement(value: 8, unit: UnitTemperature.celsius)
          let batteryTempEnd = Measurement(value: 4, unit: UnitTemperature.celsius)
          let batteryTempSymbol = {
            if batteryTempEnd.value < 10 { return "batteryblock.stack.badge.snowflake" }
            if batteryTempEnd.value < 50 { return "batteryblock.stack" }
            return "batteryblock.stack.trianglebadge.exclamationmark"
          }()

          DokoGridRangeButton(
            rangeName: "Battery Temperature",
            symbolColor: .yellow,
            symbolName: batteryTempSymbol,
            startValue: String(format: "%.0f", batteryTempStart.value),
            startUnit: batteryTempStart.unit.symbol,
            startColor: .primary,
            endValue: String(format: "%.0f", batteryTempEnd.value),
            endUnit: batteryTempEnd.unit.symbol,
            endColor: .primary
          ) {}
        }

        GridRow {
          let energyStart = Measurement(value: 18.4, unit: UnitEnergy.kilowattHours)
          let energyEnd = Measurement(value: 42.1, unit: UnitEnergy.kilowattHours)
          DokoGridRangeButton(
            rangeName: "Energy To Empty",
            symbolColor: .red,
            symbolName: "bolt.fill",
            startValue: String(format: "%.1f", energyStart.value),
            startUnit: energyStart.unit.symbol,
            startColor: .primary,
            endValue: String(format: "%.1f", energyEnd.value),
            endUnit: energyEnd.unit.symbol,
            endColor: .primary
          ) {}
        }
      }
      .padding([.leading, .trailing], 10)
    }
    .preferredColorScheme(.dark)
  }
}

#Preview("Status Button") {
  NavigationStack {
    ScrollView {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        DokoGridStatusButton(
          leftSymbol: "togglepower",
          leftSymbolColor: .green,
          leftSymbolTitle: "Emable",
          centerSymbol: "antenna.radiowaves.left.and.right",
          centerSymbolColor: .blue,
          centerSymbolTitle: "Bluetooth",
          rightSymbol: "car",
          rightSymbolColor: .red,
          rightSymbolTitle: "Activity"
        ) {
          print("Bluetooth button pressed")
        }
        DokoGridStatusButton(
          leftSymbol: "togglepower",
          leftSymbolColor: .green,
          leftSymbolTitle: "Emable",
          centerSymbol: "antenna.radiowaves.left.and.right",
          centerSymbolColor: .blue,
          centerSymbolTitle: "Bluetooth",
          rightSymbol: nil,
          rightSymbolColor: .red,
          rightSymbolTitle: "Activity"
        ) {
          print("Bluetooth button pressed")
        }
      }
    }
    .buttonStyle(.plain)
    .listRowBackground(Color.clear)
    .padding([.leading, .trailing], 10)
    .preferredColorScheme(.dark)
  }
}

#Preview("Grid Button") {
  NavigationStack {
    ScrollView {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          DokoGridValueButton(
            color: .blue,
            value: "3210",
            units: "mi",
            symbolName: "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath",
            title: "Route"
          ) {
            print("Route button pressed")
          }
          DokoGridValueButton(
            color: .yellow,
            value: "123",
            units: nil,
            symbolName: "car",
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
            symbolName: "map",
            title: "Map"
          ) {
            print("Map button pressed")
          }
          DokoGridButton(
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
          DokoGridButton(
            color: .red,
            symbolName: "bolt",
            title: "Energy"
          ) {
            print("Energy button pressed")
          }
          DokoGridButton(
            color: .purple,
            symbolName: "chart.bar.fill",
            title: "Power"
          ) {
            print("Power button pressed")
          }
          DokoGridButton(
            color: .gray,
            symbolName: "truck.pickup.side",
            title: "F-150 Lightning"
          ) {
            print("F-150 Lightning button pressed")
          }
        }
      }

      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        DokoGridValueButton(
          color: .yellow,
          value: nil,
          units: nil,
          symbolName: "info.circle.fill",
          title: "About"
        ) {
          print("About button pressed")
        }
      }
    }
    .buttonStyle(.plain)
    .listRowBackground(Color.clear)
    .padding([.leading, .trailing], 10)
    .preferredColorScheme(.dark)
  }
}
