@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

struct SmallTripLiveActivities: View {
  let context: ActivityViewContext<TripActivityAttributes>
  
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
}

private struct StartingView: View {
  let context: ActivityViewContext<TripActivityAttributes>

  var body: some View {
    HStack(alignment: .center) {
      DokoWidgetIcon()
      Spacer()
      Text("Small Started")
        .foregroundStyle(DesignTokens.Color.primary)
    }
    .font(DesignTokens.Font.title)
    .padding()
  }
}

private struct ActiveView: View {
  let context: ActivityViewContext<TripActivityAttributes>

  var body: some View {
    let duration = context.state.duration
    let distance = context.state.distance
    let elevation = context.state.elevation
    let windSock = context.state.windSock
    HStack {
      DokoWidgetIcon()
      Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
        GridRow {
          Image(systemName: "clock")
            .font(DesignTokens.Font.caption)
            .foregroundStyle(DesignTokens.Color.duration)
            .gridColumnAlignment(.leading)
          Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
            .font(DesignTokens.Font.headline.monospacedDigit())
            .foregroundStyle(DesignTokens.Color.duration)
            .gridColumnAlignment(.trailing)
          Color.clear.frame(width: 0)
        }
        GridRow(alignment: .lastTextBaseline) {
          Image(systemName: "road.lanes")
            .font(DesignTokens.Font.caption)
            .foregroundStyle(DesignTokens.Color.primary)
            .gridColumnAlignment(.leading)
          Text(String(format: "%5.1f", distance.value))
            .font(DesignTokens.Font.headline.monospacedDigit())
            .foregroundStyle(DesignTokens.Color.primary)
            .gridColumnAlignment(.trailing)
          Text(distance.unit.symbol)
            .font(DesignTokens.Font.caption)
            .foregroundStyle(.secondary)
            .gridColumnAlignment(.leading)
        }
        if let elevation {
          GridRow(alignment: .lastTextBaseline) {
            Image(systemName: "mountain.2")
              .font(DesignTokens.Font.caption)
              .foregroundStyle(DesignTokens.Color.primary)
              .gridColumnAlignment(.leading)
            Text(String(format: "%5.0f", elevation.value))
              .font(DesignTokens.Font.headline.monospacedDigit())
              .foregroundStyle(DesignTokens.Color.primary)
              .gridColumnAlignment(.trailing)
            Text(elevation.unit.symbol)
              .font(DesignTokens.Font.caption)
              .foregroundStyle(.secondary)
              .gridColumnAlignment(.leading)
          }
        }
      }
      Spacer()
//      if let windSock {
//        WindIndicator(
//          temperature: windSock.temperature,
//          conditions: windSock.conditions,
//          course: windSock.course,
//          windSpeed: windSock.windSpeed,
//          windDirection: windSock.windDirection,
//          windCompassDirection: windSock.windCompassDirection
//        )
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//      }
      if let windSock {
        let windScale: Double = windSock.windSpeed.value < 10 ? DesignTokens.WindScale.light : windSock.windSpeed.value < 20 ? DesignTokens.WindScale.moderate : DesignTokens.WindScale.strong
        let relativeDirection = windSock.windDirection.value - windSock.course.value
        let temperature = windSock.temperature.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
        let windSpeed = windSock.windSpeed.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
        VStack(spacing: 2) {
          HStack(spacing: 4) {
            Image(systemName: windSock.conditions)
            Text(temperature)
          }
          .font(DesignTokens.Font.body)

          Image(systemName: "arrow.down")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(CGSize(width: windScale, height: windScale))
            .rotationEffect(.degrees(relativeDirection))
            .foregroundStyle(abs(relativeDirection) < 90 ? .red : .green)
            .fontWeight(.black)
            .animation(.linear, value: relativeDirection)
            .frame(width: 36, height: 36)

          Text("\(windSock.windCompassDirection), \(windSpeed)")
            .font(DesignTokens.Font.body)
        }
        .foregroundStyle(DesignTokens.Color.primary)
      }
    }
    .padding()
  }
  
//  private struct WindIndicator: View {
//    var temperature: Measurement<UnitTemperature>
//    var conditions: String
//    var course: Measurement<UnitAngle>
//    var windSpeed: Measurement<UnitSpeed>
//    var windDirection: Measurement<UnitAngle>
//    var windCompassDirection: String
//
//    var relativeDirection: Double {
//      windDirection.value - course.value
//    }
//
//    var body: some View {
//      let headWindScale: Double = windSpeed.value < 10 ? DesignTokens.WindScale.light : windSpeed.value < 20 ? DesignTokens.WindScale.moderate : DesignTokens.WindScale.strong
//
//      VStack(spacing: 2) {
//        HStack(spacing: 4) {
//          Image(systemName: conditions)
//          Text(
//            temperature.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
//          )
//        }
//        .font(DesignTokens.Font.title)
//
//        Image(systemName: "arrow.down")
//          .resizable()
//          .aspectRatio(contentMode: .fit)
//          .scaleEffect(CGSize(width: headWindScale, height: headWindScale))
//          .rotationEffect(.degrees(relativeDirection))
//          .foregroundStyle(abs(relativeDirection) < 90 ? .red : .green)
//          .fontWeight(.black)
//          .animation(.linear, value: relativeDirection)
//          .frame(width: 100, height: 90)
//
//        Text("\(windCompassDirection), \(windSpeed.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))))")
//          .font(DesignTokens.Font.title)
//      }
//      .font(.caption)
//      .foregroundStyle(DesignTokens.Color.primary)
//    }
//  }
}

private struct EndedView: View {
  let context: ActivityViewContext<TripActivityAttributes>

  var body: some View {
    HStack(alignment: .center) {
      DokoWidgetIcon()
      Spacer()
      Text("Small Ended")
        .foregroundStyle(DesignTokens.Color.primary)
    }
    .font(DesignTokens.Font.title)
    .padding()
  }
}
