@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

private protocol TripLiveActivityFonts: View {
  var activityFamily: ActivityFamily { get }
}

extension TripLiveActivityFonts {
  var laSymbol: Font { activityFamily == .small ? DesignTokens.Font.slaSymbol : DesignTokens.Font.mlaSymbol }
  var laValue: Font  { activityFamily == .small ? DesignTokens.Font.slaValue  : DesignTokens.Font.mlaValue  }
  var laUnit: Font   { activityFamily == .small ? DesignTokens.Font.slaUnit   : DesignTokens.Font.mlaUnit   }
  var laTitle: Font  { activityFamily == .small ? DesignTokens.Font.slaTitle  : DesignTokens.Font.mlaTitle  }
  var laLabel: Font  { activityFamily == .small ? DesignTokens.Font.slaLabel  : DesignTokens.Font.mlaLabel  }
  var laIconFrame: Double  { activityFamily == .small ? 24 : 45 }
  var laArrowFrame: Double  { activityFamily == .small ? 36 : 60 }
}

struct TripLiveActivities: View, TripLiveActivityFonts {
  let context: ActivityViewContext<TripActivityAttributes>
  @Environment(\.activityFamily) var activityFamily

  var body: some View {
    switch context.state.tripState {
    case .starting:
      StartingView(context: context)
    case .active:
      ActiveView(context: context)
    case .ended:
      EndedView(context: context)
    }
  }

  private struct StartingView: View, TripLiveActivityFonts {
    let context: ActivityViewContext<TripActivityAttributes>
    @Environment(\.activityFamily) var activityFamily

    var body: some View {
      HStack(alignment: .center) {
        DokoWidgetIcon(height: laIconFrame)
        Spacer()
        Text("Trip Starting")
          .foregroundStyle(DesignTokens.Color.primary)
      }
      .font(laTitle)
      .padding()
    }
  }

  private struct ActiveView: View, TripLiveActivityFonts {
    let context: ActivityViewContext<TripActivityAttributes>
    @Environment(\.activityFamily) var activityFamily

    var body: some View {
      let duration = context.state.duration
      let distance = context.state.distance
      let elevation = context.state.elevation
      //let rangeConsumed = context.state.rangeConsumed
      let windSock = context.state.windSock

      HStack(alignment: .center) {
        DokoWidgetIcon(height: laIconFrame)
        Spacer()
        Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
          GridRow(alignment: .lastTextBaseline) {
            Image(systemName: "clock")
              .font(laSymbol)
              .foregroundStyle(DesignTokens.Color.duration)
              .gridColumnAlignment(.leading)
            Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
              .font(laValue.monospacedDigit())
              .foregroundStyle(DesignTokens.Color.duration)
              .gridColumnAlignment(.trailing)
//            Color.clear.frame(width: 0)
          }
          GridRow(alignment: .lastTextBaseline) {
            Image(systemName: "road.lanes")
              .font(laSymbol)
              .foregroundStyle(DesignTokens.Color.distance)
              .gridColumnAlignment(.leading)
            Text(String(format: "%5.1f", distance.value))
              .font(laValue.monospacedDigit())
              .foregroundStyle(DesignTokens.Color.distance)
              .gridColumnAlignment(.trailing)
            Text(distance.unit.symbol)
              .font(laUnit)
              .foregroundStyle(.secondary)
              .gridColumnAlignment(.leading)
          }
          if let elevation {
            GridRow(alignment: .lastTextBaseline) {
              Image(systemName: "mountain.2")
                .font(laSymbol)
                .foregroundStyle(DesignTokens.Color.elevation)
                .gridColumnAlignment(.leading)
              Text(String(format: "%5.0f", elevation.value))
                .font(laValue.monospacedDigit())
                .foregroundStyle(DesignTokens.Color.elevation)
                .gridColumnAlignment(.trailing)
              Text(elevation.unit.symbol)
                .font(laUnit)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.leading)
            }
          }
        }

        if let windSock {
          Spacer()
          WindIndicator(
            temperature: windSock.temperature,
            conditions: windSock.conditions,
            course: windSock.course,
            windSpeed: windSock.windSpeed,
            windDirection: windSock.windDirection,
            windCompassDirection: windSock.windCompassDirection
          )
        }
      }
      .padding()
    }
  }

  private struct EndedView: View, TripLiveActivityFonts {
    let context: ActivityViewContext<TripActivityAttributes>
    @Environment(\.activityFamily) var activityFamily

    var body: some View {
      let duration = context.state.duration
      let distance = context.state.distance
      let energy = context.state.energy
      let efficiency = context.state.efficiency

      HStack(alignment: .center) {
        VStack {
          HStack {
            DokoWidgetIcon(height: laIconFrame)
            Spacer()
            Text("Trip Ended")
              .font(laValue)
              .foregroundStyle(DesignTokens.Color.primary)
          }
          
          HStack {
            Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
              GridRow(alignment: .lastTextBaseline) {
                Image(systemName: "clock")
                  .font(laSymbol)
                  .gridColumnAlignment(.leading)
                Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
                  .font(laValue.monospacedDigit())
                  .gridColumnAlignment(.trailing)
              }
              .foregroundStyle(DesignTokens.Color.duration)

              GridRow(alignment: .lastTextBaseline) {
                Image(systemName: "road.lanes")
                  .font(laSymbol)
                  .gridColumnAlignment(.leading)
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
                GridRow(alignment: .lastTextBaseline) {
                  Text(String(format: "%.1f", energy.value))
                    .font(laValue.monospacedDigit())
                    .gridColumnAlignment(.trailing)
                  Text(energy.unit.symbol)
                    .font(laUnit)
                    .gridColumnAlignment(.leading)
                }
                .foregroundStyle(DesignTokens.Color.energy)
              }
              
              if let efficiency {
                GridRow(alignment: .lastTextBaseline) {
                  Text(String(format: "%.1f", efficiency.value))
                    .font(laValue.monospacedDigit())
                    .gridColumnAlignment(.trailing)
                  Text(efficiency.unit.symbol)
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

  private struct WindIndicator: View, TripLiveActivityFonts {
    var temperature: Measurement<UnitTemperature>
    var conditions: String
    var course: Measurement<UnitAngle>
    var windSpeed: Measurement<UnitSpeed>
    var windDirection: Measurement<UnitAngle>
    var windCompassDirection: String

    @Environment(\.activityFamily) var activityFamily

    var relativeDirection: Double {
      windDirection.value - course.value
    }

    var body: some View {
      let headWindScale: Double = windSpeed.value < 10 ? DesignTokens.WindScale.light : windSpeed.value < 20 ? DesignTokens.WindScale.moderate : DesignTokens.WindScale.strong

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

extension TripActivityAttributes {
  fileprivate static var preview: TripActivityAttributes {
    TripActivityAttributes()
  }
}

extension TripActivityAttributes.ContentState {
  fileprivate static var starting: TripActivityAttributes.ContentState {
    TripActivityAttributes.ContentState(tripState: .starting)
  }

  fileprivate static var headWind: TripActivityAttributes.ContentState {
    TripActivityAttributes.ContentState(
      tripState: .active,
      duration: .seconds(1000),
      distance: .init(value: 22.0, unit: .kilometers),
      elevation: .init(value: 322.5, unit: .meters),
      rangeConsumed: .init(value: 26.4, unit: .kilometers),
      windSock: WindSock(
        course: .init(value: 90, unit: .degrees),
        temperature: .init(value: 15, unit: .celsius),
        conditions: "sun.snow",
        windSpeed: .init(value: 125, unit: .metersPerSecond),
        windDirection: .init(value: 90, unit: .degrees),
        windCompassDirection: "S"
      )
    )
  }

  fileprivate static var tailWind: TripActivityAttributes.ContentState {
    TripActivityAttributes.ContentState(
      tripState: .active,
      duration: .seconds(1000),
      distance: .init(value: 22.0, unit: .kilometers),
      elevation: .init(value: 322.5, unit: .meters),
      rangeConsumed: .init(value: 20.4, unit: .kilometers),
      windSock: WindSock(
        course: .init(value: 180, unit: .degrees),
        temperature: .init(value: 15.678, unit: .celsius),
        conditions: "cloud.drizzle.fill",
        windSpeed: .init(value: 20.12345, unit: .metersPerSecond),
        windDirection: .init(value: 0.4567, unit: .degrees),
        windCompassDirection: "N"
      )
    )
  }

  fileprivate static var noRange: TripActivityAttributes.ContentState {
    TripActivityAttributes.ContentState(
      tripState: .active,
      duration: .seconds(600),
      distance: .init(value: 22.0, unit: .kilometers),
      rangeConsumed: nil,
      windSock: WindSock(
        course: .init(value: 0, unit: .degrees),
        temperature: .init(value: 15.456, unit: .celsius),
        conditions: "cloud.rain.fill",
        windSpeed: .init(value: 20.56789, unit: .metersPerSecond),
        windDirection: .init(value: 0.2345, unit: .degrees),
        windCompassDirection: "N"
      )
    )
  }

  fileprivate static var noWind: TripActivityAttributes.ContentState {
    TripActivityAttributes.ContentState(
      tripState: .active,
      duration: .seconds(1000),
      distance: .init(value: 22.0, unit: .kilometers),
      rangeConsumed: nil
    )
  }

  fileprivate static var ended: TripActivityAttributes.ContentState {
    TripActivityAttributes.ContentState(
      tripState: .ended,
      duration: .seconds(1000),
      distance: .init(value: 22.0, unit: .kilometers),
      energy: .init(value: 7.5, unit: .kilowattHours),
      efficiency: .init(value: 2.93, unit: .kilometersPerKilowattHour),
      rangeConsumed: .init(value: 20.4, unit: .kilometers),
    )
  }
}

#Preview("Trip Live Activity", as: .content, using: TripActivityAttributes.preview) {
  TripLiveActivityWidget()
} contentStates: {
  TripActivityAttributes.ContentState.starting
  TripActivityAttributes.ContentState.tailWind
  TripActivityAttributes.ContentState.headWind
  //  TripActivityAttributes.ContentState.noRange
  //  TripActivityAttributes.ContentState.noWind
  TripActivityAttributes.ContentState.ended
}

