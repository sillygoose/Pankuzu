import SwiftUI

import DokoSharing

public struct DokoGridWeatherConditions: View {
  let startCondition: Measurement<UnitTemperature>
  let startConditionSymbol: String
  let endCondition: Measurement<UnitTemperature>
  let endConditionSymbol: String
  let meanCondition: Measurement<UnitTemperature>?
  let action: () -> Void

  public init(
    startCondition: Measurement<UnitTemperature>,
    startConditionSymbol: String,
    endCondition: Measurement<UnitTemperature>,
    endConditionSymbol: String,
    meanCondition: Measurement<UnitTemperature>? = nil,
    action: @escaping () -> Void
  ) {
    @Shared(.metric) var metric
    self.startCondition = startCondition
      .converted(to: metric ? .celsius : .fahrenheit)
    self.startConditionSymbol = startConditionSymbol
    self.endCondition = endCondition
      .converted(to: metric ? .celsius : .fahrenheit)
    self.endConditionSymbol = endConditionSymbol
    self.meanCondition = meanCondition?
      .converted(to: metric ? .celsius : .fahrenheit)
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      VStack {
        HStack {
          HStack(alignment: .bottom) {
            HStack(alignment: .top, spacing: 2) {
              Text(startCondition.value, format: .number.precision(.fractionLength(0)))
              Text(startCondition.unit.symbol)
                .font(DesignTokens.Font.headline)
                .opacity(DesignTokens.Opacity.muted)
              Image(systemName: startConditionSymbol)
            }
            Spacer()
            
            if meanCondition != nil {
              Text("Mean")
                .font(DesignTokens.Font.headline)
                .opacity(DesignTokens.Opacity.muted)
              Spacer()
            }
            
            HStack(alignment: .top, spacing: 2) {
              Image(systemName: endConditionSymbol)
              Text(endCondition.value, format: .number.precision(.fractionLength(0)))
              Text(endCondition.unit.symbol)
                .font(DesignTokens.Font.headline)
                .opacity(DesignTokens.Opacity.muted)
            }
          }
          .font(DesignTokens.Font.largeTitle)
          .bold()
          .foregroundStyle(.white)
        }

        if let meanCondition {
          HStack(alignment: .bottom, spacing: 6) {
            HStack(alignment: .top, spacing: 2) {
              Text(meanCondition.value, format: .number.precision(.fractionLength(0)))
              Text(meanCondition.unit.symbol)
                .font(DesignTokens.Font.headline)
                .opacity(DesignTokens.Opacity.muted)
            }
          }
          .font(DesignTokens.Font.title)
          .bold()
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
          DokoGridWeatherConditions(
            startCondition: Measurement(value: 20, unit: .celsius),
            startConditionSymbol: "cloud",
            endCondition: Measurement(value: 22, unit: .celsius),
            endConditionSymbol: "cloud"
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

