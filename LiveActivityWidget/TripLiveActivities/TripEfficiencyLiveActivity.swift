@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoSharing
import DokoLiveActivityManager

struct TripEfficiencyLiveActivity: View, DokoLiveActivityFonts {
  let context: ActivityViewContext<TripEfficiencyActivityAttributes>
  @Environment(\.activityFamily) var activityFamily

  var body: some View {
    Group {
      switch context.state.tripState {
      case .starting:
        StartingView(context: context)
      case .active:
        ActiveView(context: context)
      case .ended:
        EndedView(context: context)
      }
    }
    .widgetURL(URL(string: "pankuzu://trip")!)
  }

  private struct StartingView: View, DokoLiveActivityFonts {
    let context: ActivityViewContext<TripEfficiencyActivityAttributes>

    @Environment(\.activityFamily) var activityFamily

    var body: some View {
      HStack(alignment: .center) {
        Text("Trip Starting")
          .foregroundStyle(DesignTokens.Color.primary)
          .font(laTitle)
        Spacer()
      }
      .padding()
    }
  }

  private struct ActiveView: View, DokoLiveActivityFonts {
    let context: ActivityViewContext<TripEfficiencyActivityAttributes>

    @Environment(\.activityFamily) var activityFamily

    @Shared(.appSettings) var appSettings

    var body: some View {
      let efficiency = context.state.efficiency

      HStack(alignment: .center) {
        Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
          if let efficiency {
            let metricEfficiency = Measurement(
              value: efficiency,
              unit: UnitEnergyEfficiency.kilometersPerKilowattHour
            )
            let efficiency = metricEfficiency.converted(
              to: appSettings.metric ? appSettings.kWhPer100km ? .kilowattHoursPer100Kilometers : .kilometersPerKilowattHour : .milesPerKilowattHour
            )
            GridRow(alignment: .lastTextBaseline) {
              Image(systemName: "ev.charger")
                .font(laSymbol)
                .gridColumnAlignment(.leading)
                .padding(.trailing, laSymbolSpacing)
              Text(String(format: "%.2f", efficiency.value))
                .font(laValue.monospacedDigit())
                .gridColumnAlignment(.trailing)
              Text(efficiency.unit.symbol)
                .font(laUnit)
                .gridColumnAlignment(.leading)
            }
            .foregroundStyle(DesignTokens.Color.tripping)
          }
        }
      }
      .padding()
    }
  }

  private struct EndedView: View, DokoLiveActivityFonts {
    let context: ActivityViewContext<TripEfficiencyActivityAttributes>

    @Environment(\.activityFamily) var activityFamily

    @Shared(.appSettings) var appSettings

    var body: some View {
      let duration = context.state.duration
      let distance = context.state.distance
      let energy = context.state.energy
      let efficiency = context.state.efficiency
      let rangeConsumed = context.state.rangeConsumed

      HStack(alignment: .center) {
        VStack {
          HStack {
            Text("Trip Ended")
              .foregroundStyle(DesignTokens.Color.primary)
              .font(laTitle)
            Spacer()
          }

          HStack {
            Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
              GridRow(alignment: .lastTextBaseline) {
                Image(systemName: "clock")
                  .font(laSymbol)
                  .gridColumnAlignment(.leading)
                  .padding(.trailing, laSymbolSpacing)
                Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
                  .font(laValue.monospacedDigit())
                  .gridColumnAlignment(.trailing)
              }
              .foregroundStyle(DesignTokens.Color.duration)

              GridRow(alignment: .lastTextBaseline) {
                let distance = Measurement(value: distance, unit: UnitLength.kilometers)
                  .converted(to: appSettings.metric ? .kilometers : .miles)
                Image(systemName: "road.lanes")
                  .font(laSymbol)
                  .gridColumnAlignment(.leading)
                  .padding(.trailing, laSymbolSpacing)
                Text(String(format: "%5.1f", distance.value))
                  .font(laValue.monospacedDigit())
                  .gridColumnAlignment(.trailing)
                Text(distance.unit.symbol)
                  .font(laUnit)
                  .gridColumnAlignment(.leading)
              }
              .foregroundStyle(DesignTokens.Color.distance)
            }

            Spacer()

            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 2) {
              if let energy {
                let tripEnergy = Measurement(value: -energy, unit: UnitEnergy.kilowattHours)
                GridRow(alignment: .lastTextBaseline) {
                  Image(systemName: "bolt.circle.fill")
                    .font(laSymbol)
                    .gridColumnAlignment(.leading)
                    .padding(.trailing, laSymbolSpacing)
                  Text(String(format: "%.1f", tripEnergy.value))
                    .font(laValue.monospacedDigit())
                    .gridColumnAlignment(.trailing)
                  Text(tripEnergy.unit.symbol)
                    .font(laUnit)
                    .gridColumnAlignment(.leading)
                }
                .foregroundStyle(DesignTokens.Color.energy)
              }

              if let efficiency {
                let tripEfficiency = Measurement(value: efficiency, unit: UnitEnergyEfficiency.kilometersPerKilowattHour)
                  .converted(to: appSettings.metric ? appSettings.kWhPer100km ? .kilowattHoursPer100Kilometers : .kilometersPerKilowattHour : .milesPerKilowattHour)
                GridRow(alignment: .lastTextBaseline) {
                  Image(systemName: "ev.charger")
                    .font(laSymbol)
                    .gridColumnAlignment(.leading)
                    .padding(.trailing, laSymbolSpacing)
                  Text(String(format: "%.1f", tripEfficiency.value))
                    .font(laValue.monospacedDigit())
                    .gridColumnAlignment(.trailing)
                  Text(tripEfficiency.unit.symbol)
                    .font(laUnit)
                    .gridColumnAlignment(.leading)
                }
                .foregroundStyle(DesignTokens.Color.efficiency)
              }

              if let rangeConsumed {
                let tripRangeConsumed = Measurement(value: rangeConsumed, unit: UnitLength.kilometers)
                  .converted(to: appSettings.metric ? .kilometers : .miles)
                GridRow(alignment: .lastTextBaseline) {
                  Image(systemName: "road.lanes.curved.right")
                    .font(laSymbol)
                    .gridColumnAlignment(.leading)
                    .padding(.trailing, laSymbolSpacing)
                  Text(String(format: "%.1f", tripRangeConsumed.value))
                    .font(laValue.monospacedDigit())
                    .gridColumnAlignment(.trailing)
                  Text(tripRangeConsumed.unit.symbol)
                    .font(laUnit)
                    .gridColumnAlignment(.leading)
                }
                .foregroundStyle(DesignTokens.Color.efficiency)
              }
            }
          }
        }
      }
      .padding()
    }
  }

  private struct WindIndicator: View, DokoLiveActivityFonts {
    var temperature: Double
    var conditions: String
    var course: Double
    var windSpeed: Double
    var windDirection: Double
    var windCompassDirection: String

    @Environment(\.activityFamily) var activityFamily

    @Shared(.appSettings) var appSettings

    var relativeDirection: Double {
      windDirection - course
    }

    var body: some View {
      let headWindScale: Double = windSpeed < 10 ? DesignTokens.WindScale.light : windSpeed < 20 ? DesignTokens.WindScale.moderate : DesignTokens.WindScale.strong

      let temperature = Measurement(value: temperature, unit: UnitTemperature.celsius)
        .converted(to: appSettings.metric ? .celsius : .fahrenheit)
      let windSpeed = Measurement(value: windSpeed, unit: UnitSpeed.kilometersPerHour)
        .converted(to: appSettings.metric ? .kilometersPerHour : .milesPerHour)

      VStack(spacing: 2) {
        HStack(spacing: 4) {
          Image(systemName: conditions)
          Text(
            temperature.formatted(
              .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))
            ))
        }
        .font(laLabel)

        Image(systemName: "arrow.down")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .scaleEffect(CGSize(width: headWindScale, height: headWindScale))
          .rotationEffect(.degrees(relativeDirection))
          .foregroundStyle(abs(relativeDirection) < 90 ? .red : .green)
          .fontWeight(.black)
          .animation(.linear, value: relativeDirection)
          .frame(width: laArrowFrame, height: laArrowFrame)

        Text("\(windCompassDirection), \(windSpeed.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))))")
          .font(laLabel)
      }
      .font(.caption)
      .foregroundStyle(DesignTokens.Color.weather)
    }
  }
}

extension TripEfficiencyActivityAttributes {
  fileprivate static var preview: TripEfficiencyActivityAttributes {
    TripEfficiencyActivityAttributes()
  }
}

extension TripEfficiencyActivityAttributes.ContentState {
  fileprivate static var starting: TripEfficiencyActivityAttributes.ContentState {
    TripEfficiencyActivityAttributes.ContentState(tripState: .starting)
  }

  fileprivate static var headWind: TripEfficiencyActivityAttributes.ContentState {
    TripEfficiencyActivityAttributes.ContentState(
      tripState: .active,
      duration: .seconds(1000),
      distance: 22.0,
      efficiency: 4.5,
      elevation: 2322.5,
      rangeConsumed: 26.4,
      windSock: WindSock(
        course: 90,
        temperature: 15,
        conditions: "sun.snow",
        windSpeed: 125,
        windDirection: 90,
        windCompassDirection: "S"
      )
    )
  }

  fileprivate static var tailWind: TripEfficiencyActivityAttributes.ContentState {
    TripEfficiencyActivityAttributes.ContentState(
      tripState: .active,
      duration: .seconds(1000),
      distance: 22.0,
      elevation: 4322.5,
      rangeConsumed: 20.4,
      windSock: WindSock(
        course: 180,
        temperature: 15.678,
        conditions: "cloud.drizzle.fill",
        windSpeed: 20.12345,
        windDirection: 0.4567,
        windCompassDirection: "N"
      )
    )
  }

  fileprivate static var ended: TripEfficiencyActivityAttributes.ContentState {
    TripEfficiencyActivityAttributes.ContentState(
      tripState: .ended,
      duration: .seconds(1000),
      distance: 22.0,
      efficiency: 5.5,
      rangeConsumed: 20.4,
    )
  }
}

#Preview("Trip Efficiency Live Activity", as: .content, using: TripEfficiencyActivityAttributes.preview) {
  TripEfficiencyLiveActivityWidget()
} contentStates: {
  TripEfficiencyActivityAttributes.ContentState.starting
  TripEfficiencyActivityAttributes.ContentState.tailWind
  TripEfficiencyActivityAttributes.ContentState.headWind
  TripEfficiencyActivityAttributes.ContentState.ended
}
