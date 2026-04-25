import SwiftUI

public struct GridRangeButton: View {
  let rangeName: String
  let startValue: String
  let startUnit: String
  let startColor: Color
  let startSymbol: String
  let endValue: String
  let endUnit: String
  let endColor: Color
  let endSymbol: String
  let action: () -> Void

  public init(
    rangeName: String = "",
    startValue: String, startUnit: String, startColor: Color, startSymbol: String = "bolt",
    endValue: String, endUnit: String, endColor: Color, endSymbol: String = "bolt",
    action: @escaping () -> Void
  ) {
    self.rangeName = rangeName
    self.startValue = startValue
    self.startUnit = startUnit
    self.startColor = startColor
    self.startSymbol = startSymbol
    self.endValue = endValue
    self.endUnit = endUnit
    self.endColor = endColor
    self.endSymbol = endSymbol
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      VStack(alignment: .leading) {
        HStack(alignment: .bottom) {
          Image(systemName: startSymbol)
            .font(DesignTokens.Font.title)
            .bold()
            .foregroundStyle(startColor)
            .frame(width: 48, height: 32)

          HStack {
            VStack(alignment: .leading) {
              HStack(alignment: .bottom, spacing: 2) {
                Text(startValue)
                  .font(DesignTokens.Font.title)
                  .fontDesign(.rounded)
                  .bold()
                  .foregroundStyle(DesignTokens.Color.value)

                Text(startUnit)
                  .lineLimit(1)
                  .font(DesignTokens.Font.headline)
                  .bold()
                  .foregroundStyle(DesignTokens.Color.value)
              }
            }
          }

          Spacer()

          VStack(alignment: .trailing) {
            HStack(alignment: .bottom, spacing: 2) {
              Text(endValue)
                .font(DesignTokens.Font.title)
                .fontDesign(.rounded)
                .bold()
                .foregroundStyle(DesignTokens.Color.value)

              Text(endUnit)
                .lineLimit(1)
                .font(DesignTokens.Font.headline)
                .bold()
                .foregroundStyle(DesignTokens.Color.value)

                Image(systemName: endSymbol)
                  .font(DesignTokens.Font.title)
                  .bold()
                  .foregroundStyle(endColor)
                  .frame(width: 48, height: 32)
            }

          }
        }

        Text(rangeName)
          .font(DesignTokens.Font.headline)
          .bold()
          .foregroundStyle(.gray)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity, alignment: .center)
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
          let couplerTempStartMetric: Double = 12
          let couplerTempEndMetric: Double = 60
          let (couplerTempStartColor, couplerTempStartIcon) = {
            if couplerTempStartMetric < 30 { return (DesignTokens.Color.cool, "ev.plug.dc.nacs") }
            if couplerTempStartMetric < 50 { return (DesignTokens.Color.warm, "ev.plug.dc.nacs") }
            return (DesignTokens.Color.hot, "ev.plug.dc.nacs")
          }()
          let (couplerTempEndColor, couplerTempEndIcon) = {
            if couplerTempEndMetric < 30 { return (DesignTokens.Color.cool, "ev.plug.dc.nacs") }
            if couplerTempEndMetric < 50 { return (DesignTokens.Color.warm, "ev.plug.dc.nacs") }
            return (DesignTokens.Color.hot, "ev.plug.dc.nacs")
          }()
          let couplerTempStart = Measurement(value: couplerTempStartMetric, unit: UnitTemperature.celsius)
          let couplerTempEnd = Measurement(value: couplerTempEndMetric, unit: UnitTemperature.celsius)

          GridRangeButton(
            rangeName: "Coupler Temperature",
            startValue: String(format: "%.0f", couplerTempStart.value),
            startUnit: couplerTempStart.unit.symbol,
            startColor: couplerTempStartColor,
            startSymbol: couplerTempStartIcon,
            endValue: String(format: "%.0f", couplerTempEnd.value),
            endUnit: couplerTempEnd.unit.symbol,
            endColor: couplerTempEndColor,
            endSymbol: couplerTempEndIcon
          ) {}
        }

        GridRow {
          let batteryTempStartMetric: Double = 28
          let batteryTempEndMetric: Double = 54
          let (batteryTempStartColor, batteryTempStartIcon) = {
            if batteryTempStartMetric < 10 { return (DesignTokens.Color.cool, "batteryblock.stack.badge.snowflake") }
            if batteryTempStartMetric < 40 { return (DesignTokens.Color.warm, "batteryblock.stack") }
            return (DesignTokens.Color.hot, "batteryblock.stack.trianglebadge.exclamationmark")
          }()
          let (batteryTempEndColor, batteryTempEndIcon) = {
            if batteryTempEndMetric < 10 { return (DesignTokens.Color.cool, "batteryblock.stack.badge.snowflake") }
            if batteryTempEndMetric < 40 { return (DesignTokens.Color.warm, "batteryblock.stack") }
            return (DesignTokens.Color.hot, "batteryblock.stack.trianglebadge.exclamationmark")
          }()
          let batteryTempStart = Measurement(value: batteryTempStartMetric, unit: UnitTemperature.celsius)
          let batteryTempEnd = Measurement(value: batteryTempEndMetric, unit: UnitTemperature.celsius)

          GridRangeButton(
            rangeName: "Battery Temperature",
            startValue: String(format: "%.0f", batteryTempStart.value),
            startUnit: batteryTempStart.unit.symbol,
            startColor: batteryTempStartColor,
            startSymbol: batteryTempStartIcon,
            endValue: String(format: "%.0f", batteryTempEnd.value),
            endUnit: batteryTempEnd.unit.symbol,
            endColor: batteryTempEndColor,
            endSymbol: batteryTempEndIcon
          ) {}
        }

        GridRow {
          let energyToEmptyStartRaw: Double = 78.3
          let energyToEmptyEndRaw: Double = 32.6
          let (energyToEmptyStartColor, energyToEmptyStartIcon) = {
            if energyToEmptyStartRaw < 25 { return (Color.red, "bolt") }
            if energyToEmptyStartRaw < 50 { return (Color.yellow,"bolt") }
            return (Color.green, "bolt")
          }()
          let (energyToEmptyEndColor, energyToEmptyEndIcon) = {
            if energyToEmptyEndRaw < 25 { return (Color.red, "bolt") }
            if energyToEmptyEndRaw < 50 { return (Color.yellow,"bolt") }
            return (Color.green, "bolt")
          }()
          let energyToEmptyStart = Measurement(value: energyToEmptyStartRaw, unit: UnitEnergy.kilowattHours)
          let energyToEmptyEnd = Measurement(value: energyToEmptyEndRaw, unit: UnitEnergy.kilowattHours)
          GridRangeButton(
            rangeName: "Energy To Empty",
            startValue: String(format: "%.1f", energyToEmptyStart.value),
            startUnit: energyToEmptyStart.unit.symbol,
            startColor: energyToEmptyStartColor,
            startSymbol: energyToEmptyStartIcon,
            endValue: String(format: "%.1f", energyToEmptyEnd.value),
            endUnit: energyToEmptyEnd.unit.symbol,
            endColor: energyToEmptyEndColor,
            endSymbol: energyToEmptyEndIcon,
          ) {}
        }
      }
      .padding([.leading, .trailing], 10)
    }
    .preferredColorScheme(.dark)
  }
}
