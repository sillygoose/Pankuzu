import SwiftUI

public struct DokoGridCount: View {
  let color: Color
  let value: String
  let units: String
  let symbolName: String
  let pulseSymbol: Bool
  let title: String

  public init(
    color: Color, value: String, units: String,
    symbolName: String,
    pulseSymbol: Bool = false,
    title: String
  ) {
    self.color = color
    self.value = value
    self.units = units
    self.symbolName = symbolName
    self.pulseSymbol = pulseSymbol
    self.title = title
  }

  public var body: some View {
    VStack {
      HStack {
        if pulseSymbol {
          Image(systemName: symbolName)
            .font(DesignTokens.Font.title)
            .bold()
            .foregroundStyle(color)
            .symbolEffect(.pulse, options: .repeating)
        } else {
          Image(systemName: symbolName)
            .font(DesignTokens.Font.title)
            .bold()
            .foregroundStyle(color)
        }
        Spacer()
        Text(value)
          .font(DesignTokens.Font.title)
          .fontDesign(.rounded)
          .bold()
          .foregroundStyle(DesignTokens.Color.label)
      }
      HStack {
        Text(title)
          .lineLimit(1)
          .font(DesignTokens.Font.headline)
          .opacity(DesignTokens.Opacity.subtle)
        Spacer()
        Text(units)
          .lineLimit(1)
          .font(DesignTokens.Font.callout)
      }
    }
    .padding(DesignTokens.Padding.cardInsets)
    .background(DesignTokens.Color.cardBackground)
    .cornerRadius(DesignTokens.CornerRadius.medium)
  }
}

#Preview("DokoGridCount") {
  NavigationStack {
    ScrollView {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        let odometer: Measurement<UnitLength> = .init(value: 150324.7, unit: .miles)
        GridRow {
          DokoGridCount(
            color: .yellow,
            value: String(format: "%.1f", odometer.value as CVarArg),
            units: odometer.unit.symbol,
            symbolName: "gauge.open.with.lines.needle.33percent",
            title: "Odometer"
          )
        }
      }

      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        let duration: Duration = .seconds(600)
        let distance = Measurement(
          value: 10,
          unit: UnitLength.kilometers
        )
        let averageSpeed = Measurement(
          value: duration == .seconds(0)
          ? 0 : (distance.value / Double(duration.components.seconds)) * 3600,
          unit: UnitSpeed.kilometersPerHour
        )
        GridRow {
          DokoGridCount(
            color: .blue,
            value: String(format: "%.1f", distance.value as CVarArg),
            units: distance.unit.symbol,
            symbolName: "road.lanes",
            pulseSymbol: true,
            title: "Distance"
          )
          DokoGridCount(
            color: .orange,
            value: String(format: "%.0f", averageSpeed.value as CVarArg),
            units: averageSpeed.unit.symbol,
            symbolName: "powermeter",
            title: "Avg. Speed"
          )
        }
        GridRow {
          let socStart = 80.0
          let (socStartColor, socStartIcon) = {
            if socStart < 25 { return (Color.red, "battery.25percent") }
            if socStart < 50 { return (Color.yellow,"battery.50percent") }
            return (Color.green, "battery.75percent")
          }()
          DokoGridCount(
            color: socStartColor,
            value: String(format: "%.0f", socStart),
            units: "%",
            symbolName: socStartIcon,
            title: "SoC Start"
          )
          let socEnd = 75.0
          let (socEndColor, socEndIcon) = {
            if socEnd < 25 { return (Color.red, "battery.25percent") }
            if socEnd < 50 { return (Color.yellow,"battery.50percent") }
            return (Color.green, "battery.75percent")
          }()
          DokoGridCount(
            color: socEndColor,
            value: String(format: "%.0f", socEnd),
            units: "%",
            symbolName: socEndIcon,
            title: "SoC End"
          )
        }
      }
    }
    .buttonStyle(.plain)
    .listRowBackground(Color.clear)
    .padding([.leading, .trailing], 10)
    .preferredColorScheme(.dark)
  }
}
