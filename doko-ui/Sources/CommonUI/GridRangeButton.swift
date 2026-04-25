import SwiftUI

public struct GridRangeButton: View {
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
      //      HStack(spacing: 12) {
      VStack(alignment: .leading) {
        HStack(alignment: .bottom) {
          Image(systemName: symbolName)
            .font(DesignTokens.Font.title)
            .bold()
            .foregroundStyle(symbolColor)
            .frame(width: 32, height: 32)

          Spacer()

          HStack {
            VStack(alignment: .trailing) {
              Text("Start")
                .font(DesignTokens.Font.headline)
                .foregroundStyle(.gray)

              HStack(alignment: .bottom, spacing: 2) {
                Text(startValue)
                  .font(DesignTokens.Font.title)
                  .fontDesign(.rounded)
                  .bold()
                  .foregroundStyle(startColor)

                Text(startUnit)
                  .lineLimit(1)
                  .font(DesignTokens.Font.headline)
                  .bold()
                  .foregroundStyle(startColor)
              }
            }
          }

          Spacer()

          VStack(alignment: .trailing) {
            Text("End")
              .font(DesignTokens.Font.headline)
              .foregroundStyle(.gray)

            HStack(alignment: .bottom, spacing: 0) {
              Text(endValue)
                .font(DesignTokens.Font.title)
                .fontDesign(.rounded)
                .bold()
                .foregroundStyle(endColor)

              Text(endUnit)
                .lineLimit(1)
                .font(DesignTokens.Font.headline)
                .bold()
                .foregroundStyle(endColor)
            }
          }
        }

        Text(rangeName)
          .font(DesignTokens.Font.headline)
          .bold()
          .foregroundStyle(symbolColor)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
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
          GridRangeButton(
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

          GridRangeButton(
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
          GridRangeButton(
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
