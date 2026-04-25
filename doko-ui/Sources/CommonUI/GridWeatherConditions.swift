import SwiftUI

import DokoSharing

public struct GridWeatherConditions: View {
  let startTemperature: Measurement<UnitTemperature>
  let startConditionSymbol: String
  let endTemperature: Measurement<UnitTemperature>
  let endConditionSymbol: String
  let title: String
  let action: () -> Void

  public init(
    startTemperature: Double,
    startConditionSymbol: String,
    endTemperature: Double,
    endConditionSymbol: String,
    title: String = "",
    action: @escaping () -> Void
  ) {
    @Shared(.appSettings) var appSettings
    self.startTemperature = Measurement(value: startTemperature, unit: UnitTemperature.celsius)
      .converted(to: appSettings.metric ? .celsius : .fahrenheit)
    self.startConditionSymbol = startConditionSymbol
    self.endTemperature = Measurement(value: endTemperature, unit: UnitTemperature.celsius)
      .converted(to: appSettings.metric ? .celsius : .fahrenheit)
    self.endConditionSymbol = endConditionSymbol
    self.title = title
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      VStack {
        HStack {
          HStack(alignment: .bottom) {
            HStack(alignment: .top, spacing: 2) {
              Text(startTemperature.value, format: .number.precision(.fractionLength(0)))
              Text(startTemperature.unit.symbol)
                .font(DesignTokens.Font.headline)
                .opacity(DesignTokens.Opacity.muted)
              Image(systemName: startConditionSymbol)
            }
            Spacer()

            HStack(alignment: .top, spacing: 2) {
              Image(systemName: endConditionSymbol)
              Text(endTemperature.value, format: .number.precision(.fractionLength(0)))
              Text(endTemperature.unit.symbol)
                .font(DesignTokens.Font.headline)
                .opacity(DesignTokens.Opacity.muted)
            }
          }
          .font(DesignTokens.Font.largeTitle)
          .bold()
          .foregroundStyle(.white)
        }

        HStack {
          Text(title)
            .font(DesignTokens.Font.headline)
            .opacity(DesignTokens.Opacity.muted)
            .foregroundStyle(.white)
        }
      }
    }
    .buttonStyle(.borderless)
    .padding(DesignTokens.Padding.cardInsetsWide)
    .background(DesignTokens.Color.secondaryGroupedBackground)
    .cornerRadius(DesignTokens.CornerRadius.medium)
  }
}

#Preview("GridWeatherConditions") {
  NavigationStack {
    ScrollView {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridRow {
          GridWeatherConditions(
            startTemperature: 20,
            startConditionSymbol: "cloud",
            endTemperature: 22,
            endConditionSymbol: "cloud",
            title: "Trip Conditions"
          ) {
            print("Weather Conditions button pressed")
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

