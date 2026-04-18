@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

struct MediumTripLiveActivities: View {
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
  
  private struct StartingView: View {
    let context: ActivityViewContext<TripActivityAttributes>
    
    var body: some View {
      HStack(alignment: .center) {
        DokoWidgetIcon()
        Spacer()
        Text("Trip Starting")
          .foregroundStyle(DesignTokens.Color.primary)
      }
      .font(DesignTokens.Font.mlaTitle)
      .padding()
    }
  }
  
  private struct ActiveView: View {
    let context: ActivityViewContext<TripActivityAttributes>
    
    var body: some View {
      let duration = context.state.duration
      let distance = context.state.distance
      let elevation = context.state.elevation
      let rangeConsumed = context.state.rangeConsumed
      let windSock = context.state.windSock
      
      HStack(alignment: .center) {
        DokoWidgetIcon()
        Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
          GridRow(alignment: .lastTextBaseline) {
            Image(systemName: "clock")
              .font(DesignTokens.Font.mlaSymbol)
              .foregroundStyle(DesignTokens.Color.duration)
              .gridColumnAlignment(.leading)
            Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
              .font(DesignTokens.Font.mlaValue.monospacedDigit())
              .foregroundStyle(DesignTokens.Color.duration)
              .gridColumnAlignment(.trailing)
            Color.clear.frame(width: 0)
          }
          GridRow(alignment: .lastTextBaseline) {
            Image(systemName: "road.lanes")
              .font(DesignTokens.Font.mlaSymbol)
              .foregroundStyle(DesignTokens.Color.distance)
              .gridColumnAlignment(.leading)
            Text(String(format: "%5.1f", distance.value))
              .font(DesignTokens.Font.mlaValue.monospacedDigit())
              .foregroundStyle(DesignTokens.Color.distance)
              .gridColumnAlignment(.trailing)
            Text(distance.unit.symbol)
              .font(DesignTokens.Font.mlaUnit)
              .foregroundStyle(.secondary)
              .gridColumnAlignment(.leading)
          }
          if let elevation {
            GridRow(alignment: .lastTextBaseline) {
              Image(systemName: "mountain.2")
                .font(DesignTokens.Font.mlaSymbol)
                .foregroundStyle(DesignTokens.Color.elevation)
                .gridColumnAlignment(.leading)
              Text(String(format: "%5.0f", elevation.value))
                .font(DesignTokens.Font.mlaValue.monospacedDigit())
                .foregroundStyle(DesignTokens.Color.elevation)
                .gridColumnAlignment(.trailing)
              Text(elevation.unit.symbol)
                .font(DesignTokens.Font.mlaUnit)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.leading)
            }
          }
        }
//        Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 6) {
//          let distanceColor = rangeConsumed.map { $0.value > distance.value } == true
//          ? DesignTokens.Color.rangeOver
//          : DesignTokens.Color.rangeUnder
//          
//          GridRow(alignment: .lastTextBaseline) {
//            Image(systemName: "clock")
//              .font(DesignTokens.Font.mlaSymbol)
//              .gridColumnAlignment(.leading)
//            HStack(alignment: .firstTextBaseline, spacing: 2) {
//              Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
//                .font(DesignTokens.Font.mlaValue)
//            }
//            .gridColumnAlignment(.trailing)
//            Text("")
//              .font(DesignTokens.Font.mlaUnit)
//          }
//          .foregroundStyle(DesignTokens.Color.duration)
//          
//          GridRow(alignment: .lastTextBaseline) {
//            Image(systemName: "road.lanes")
//              .font(DesignTokens.Font.mlaSymbol)
//              .foregroundStyle(distanceColor)
//              .gridColumnAlignment(.leading)
//            HStack(alignment: .firstTextBaseline, spacing: 2) {
//              let formattedMeasurement = String(format: "%.1f", distance.value)
//              Text(formattedMeasurement)
//                .font(DesignTokens.Font.mlaValue.monospacedDigit())
//              Text(distance.unit.symbol)
//                .font(DesignTokens.Font.mlaUnit)
//            }
//            .foregroundStyle(distanceColor)
//            .gridColumnAlignment(.trailing)
//          }
//
//          if let elevation {
//            GridRow(alignment: .lastTextBaseline) {
//              Image(systemName: "mountain.2")
//                .font(DesignTokens.Font.mlaSymbol)
//                .foregroundStyle(DesignTokens.Color.primary)
//                .gridColumnAlignment(.leading)
//              HStack(alignment: .firstTextBaseline, spacing: 2) {
//                Text(String(format: "%4.0f", elevation.value))
//                  .font(DesignTokens.Font.mlaValue.monospacedDigit())
//                  .foregroundStyle(DesignTokens.Color.primary)
//                  .gridColumnAlignment(.trailing)
//                Text(elevation.unit.symbol)
//                  .font(DesignTokens.Font.mlaUnit)
//                  .foregroundStyle(.secondary)
//                  .gridColumnAlignment(.leading)
//              }
//              .gridColumnAlignment(.trailing)
//            }
//          }
//        }
        //.frame(maxWidth: .infinity, alignment: .leading)

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
          //.frame(maxWidth: .infinity, maxHeight: .infinity)
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
          .font(DesignTokens.Font.mlaLabel)

          Image(systemName: "arrow.down")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(CGSize(width: headWindScale, height: headWindScale))
            .rotationEffect(.degrees(relativeDirection))
            .foregroundStyle(abs(relativeDirection) < 90 ? .red : .green)
            .fontWeight(.black)
            .animation(.linear, value: relativeDirection)
//            .font(DesignTokens.Font.mlaTitle)
            //.frame(width: 60, height: 60)

          Text("\(windCompassDirection), \(windSpeed.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))))")
            .font(DesignTokens.Font.mlaLabel)
        }
        .font(.caption)
        .foregroundStyle(DesignTokens.Color.primary)
      }
    }
  }
  
  private struct EndedView: View {
    let context: ActivityViewContext<TripActivityAttributes>
    
    var body: some View {
      HStack(alignment: .center) {
        DokoWidgetIcon()
        Spacer()
        Text("Trip Ended")
          .foregroundStyle(DesignTokens.Color.primary)
      }
      .font(DesignTokens.Font.mlaTitle)
      .padding()
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
    TripActivityAttributes.ContentState(tripState: .ended)
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
