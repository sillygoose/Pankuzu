@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

struct TripLockScreen: View {
  let context: ActivityViewContext<TripActivityAttributes>

  @Environment(\.activityFamily) var activityFamily

  var body: some View {
    if activityFamily == .small {
      TripSmallView(context: context)
    } else {
      switch context.state.tripState {
      case .starting:
        TripStartingView()
      case .active:
        TripActiveView(
          duration: context.state.duration,
          distance: context.state.distance,
          rangeConsumed: context.state.rangeConsumed,
          windSock: context.state.windSock
        )
      case .ended:
        TripEndedView()
      }
    }
  }
}

private struct TripSmallView: View {
  let context: ActivityViewContext<TripActivityAttributes>

  var body: some View {
    if let windSock = context.state.windSock {
      let relativeDirection = windSock.windDirection.value - windSock.course.value

      HStack {
        Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
          GridRow {
            Image(systemName: "clock")
              .font(DesignTokens.Font.caption)
              .foregroundStyle(DesignTokens.Color.duration)
              .gridColumnAlignment(.leading)
            Text(context.state.duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
              .font(DesignTokens.Font.title.monospacedDigit())
              .foregroundStyle(DesignTokens.Color.duration)
              .gridColumnAlignment(.trailing)
            Color.clear.frame(width: 0)
          }
          GridRow(alignment: .lastTextBaseline) {
            Image(systemName: "road.lanes")
              .font(DesignTokens.Font.caption)
              .foregroundStyle(DesignTokens.Color.primary)
              .gridColumnAlignment(.leading)
            Text(String(format: "%5.1f", context.state.distance.value))
              .font(DesignTokens.Font.title.monospacedDigit())
              .foregroundStyle(DesignTokens.Color.primary)
              .gridColumnAlignment(.trailing)
            Text(context.state.distance.unit.symbol)
              .font(DesignTokens.Font.caption)
              .foregroundStyle(.secondary)
              .gridColumnAlignment(.leading)
          }
        }
        Spacer()
        VStack(spacing: 2) {
          HStack(spacing: 4) {
            Image(systemName: windSock.conditions)
            Text(windSock.temperature.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))))
          }
          .font(DesignTokens.Font.caption)

          Image(systemName: "arrow.down")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .rotationEffect(.degrees(relativeDirection))
            .foregroundStyle(abs(relativeDirection) < 90 ? .red : .green)
            .fontWeight(.black)
            .animation(.linear, value: relativeDirection)
            .frame(width: 32, height: 32)

          Text("\(windSock.windCompassDirection), \(windSock.windSpeed.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))))")
            .font(DesignTokens.Font.caption)
        }
        .foregroundStyle(DesignTokens.Color.primary)
      }
      .padding()
    }
  }
}

struct TripStartingView: View {
  var body: some View {
    HStack(alignment: .center) {
      Image(systemName: "car")
        .foregroundStyle(DesignTokens.Color.tripping)
      Spacer()
      Text("Trip Started")
        .foregroundStyle(DesignTokens.Color.primary)
    }
    .font(DesignTokens.Font.largeTitle)
    .padding()
  }
}

struct TripActiveView: View {
  let duration: Duration
  let distance: Measurement<UnitLength>
  let rangeConsumed: Measurement<UnitLength>?
  let windSock: WindSock?

  var body: some View {
    HStack(alignment: .center) {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 12) {
        let distanceColor = rangeConsumed.map { $0.value > distance.value } == true
          ? DesignTokens.Color.rangeOver
          : DesignTokens.Color.rangeUnder

        GridRow {
          Image(systemName: "clock")
            .font(DesignTokens.Font.title)
            .gridColumnAlignment(.trailing)
          Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
            .font(DesignTokens.Font.largeTitle)
            .gridColumnAlignment(.leading)
        }
        .foregroundStyle(DesignTokens.Color.duration)

        GridRow {
          Image(systemName: "road.lanes")
            .font(DesignTokens.Font.title)
            .foregroundStyle(distanceColor)
          MeasurementValueView(
            measurement: distance,
            color: distanceColor,
            fractionDigits: 1
          )
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if let windSock {
        WindIndicator(
          temperature: windSock.temperature,
          conditions: windSock.conditions,
          course: windSock.course,
          windSpeed: windSock.windSpeed,
          windDirection: windSock.windDirection,
          windCompassDirection: windSock.windCompassDirection
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .padding()
  }

  private struct WindIndicator: View {
    var temperature: Measurement<UnitTemperature>
    var conditions: String
    var course: Measurement<UnitAngle>
    var windSpeed: Measurement<UnitSpeed>
    var windDirection: Measurement<UnitAngle>
    var windCompassDirection: String

    var relativeDirection: Double {
      windDirection.value - course.value
    }

    var body: some View {
      let headWindScale: Double = windSpeed.value < 10 ? DesignTokens.WindScale.light : windSpeed.value < 20 ? DesignTokens.WindScale.moderate : DesignTokens.WindScale.strong

      VStack(spacing: 2) {
        HStack(spacing: 4) {
          Image(systemName: conditions)
          Text(
            temperature.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
          )
        }
        .font(DesignTokens.Font.title)

        Image(systemName: "arrow.down")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .scaleEffect(CGSize(width: headWindScale, height: headWindScale))
          .rotationEffect(.degrees(relativeDirection))
          .foregroundStyle(abs(relativeDirection) < 90 ? .red : .green)
          .fontWeight(.black)
          .animation(.linear, value: relativeDirection)
          .frame(width: 100, height: 90)

        Text("\(windCompassDirection), \(windSpeed.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))))")
          .font(DesignTokens.Font.title)
      }
      .font(.caption)
      .foregroundStyle(DesignTokens.Color.primary)
    }
  }
}

struct TripEndedView: View {
  var body: some View {
    HStack(alignment: .center) {
      Image(systemName: "car")
        .foregroundStyle(DesignTokens.Color.tripping)
      Spacer()
      Text("Trip Ended")
        .foregroundStyle(DesignTokens.Color.primary)
    }
    .font(DesignTokens.Font.largeTitle)
    .padding()
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
      rangeConsumed: .init(value: 26.4, unit: .kilometers),
      windSock: WindSock(
        course: .init(value: 90, unit: .degrees),
        temperature: .init(value: 15, unit: .celsius),
        conditions: "sun.snow",
        windSpeed: .init(value: 125, unit: .metersPerSecond),
        windDirection: .init(value: 180, unit: .degrees),
        windCompassDirection: "S"
      )
    )
  }

  fileprivate static var tailWind: TripActivityAttributes.ContentState {
    TripActivityAttributes.ContentState(
      tripState: .active,
      duration: .seconds(1000),
      distance: .init(value: 22.0, unit: .kilometers),
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
    TripActivityAttributes.ContentState(tripState: .ended)
  }
}

#Preview("Trip Live Activity", as: .content, using: TripActivityAttributes.preview) {
  TripLiveActivityWidget()
} contentStates: {
  TripActivityAttributes.ContentState.starting
  TripActivityAttributes.ContentState.headWind
  TripActivityAttributes.ContentState.tailWind
  TripActivityAttributes.ContentState.noRange
  TripActivityAttributes.ContentState.noWind
  TripActivityAttributes.ContentState.ended
}

