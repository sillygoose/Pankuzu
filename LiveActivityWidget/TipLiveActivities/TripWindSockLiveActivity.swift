@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoSharing
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
  var laIconFrame: Double  { activityFamily == .small ? 16 : 36 }
  var laArrowFrame: Double  { activityFamily == .small ? 36 : 60 }
}

struct TripWindSockLiveActivity: View, TripLiveActivityFonts {
  let context: ActivityViewContext<TripWindSockActivityAttributes>
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

  private struct StartingView: View, TripLiveActivityFonts {
    let context: ActivityViewContext<TripWindSockActivityAttributes>
    
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
    let context: ActivityViewContext<TripWindSockActivityAttributes>
    
    @Environment(\.activityFamily) var activityFamily
    
    @Shared(.appSettings) var appSettings

    var body: some View {
      let distance = context.state.distance
      let elevation = context.state.elevation
      let efficiency = context.state.efficiency
      let windSock = context.state.windSock

      HStack(alignment: .center) {
        Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
          GridRow(alignment: .lastTextBaseline) {
            let distance = Measurement(value: distance, unit: UnitLength.kilometers)
              .converted(to: appSettings.metric ? .kilometers : .miles)
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
              Text(String(format: "%.2f", efficiency.value))
                .font(laValue.monospacedDigit())
                .gridColumnAlignment(.trailing)
              Text(efficiency.unit.symbol)
                .font(laUnit)
                .gridColumnAlignment(.leading)
            }
            .foregroundStyle(DesignTokens.Color.tripping)
          }

          if let elevation {
            let elevation = Measurement(value: elevation, unit: UnitLength.meters)
              .converted(to: appSettings.metric ? .meters : .feet)
            GridRow(alignment: .lastTextBaseline) {
              Image(systemName: "mountain.2")
                .font(laSymbol)
                .gridColumnAlignment(.leading)
              Text(String(format: "%5.0f", elevation.value))
                .font(laValue.monospacedDigit())
                .gridColumnAlignment(.trailing)
              Text(elevation.unit.symbol)
                .font(laUnit)
                .gridColumnAlignment(.leading)
            }
            .foregroundStyle(DesignTokens.Color.elevation)
          }
        }

        Spacer()
        
        if let windSock {
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

  private struct EndedView : View, TripLiveActivityFonts {
    let context: ActivityViewContext<TripWindSockActivityAttributes>
    
    @Environment(\.activityFamily) var activityFamily
    
    @Shared(.appSettings) var appSettings

    var body: some View {
      let duration = context.state.duration
      let distance = context.state.distance
      let energy = context.state.efficiency

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
                let distance = Measurement(value: distance, unit: UnitLength.kilometers)
                  .converted(to: appSettings.metric ? .kilometers : .miles)
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
                let energy = Measurement(value: energy, unit: UnitEnergy.kilowattHours)
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
              
              if let energy {
                let kmPerkWh = distance / energy
                let efficiency = Measurement(value: kmPerkWh, unit: UnitEnergyEfficiency.kilometersPerKilowattHour)
                  .converted(to: appSettings.metric ? appSettings.kWhPer100km ? .kilowattHoursPer100Kilometers : .kilometersPerKilowattHour : .milesPerKilowattHour)
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

extension TripWindSockActivityAttributes {
  fileprivate static var preview: TripWindSockActivityAttributes {
    TripWindSockActivityAttributes()
  }
}

extension TripWindSockActivityAttributes.ContentState {
  fileprivate static var starting: TripWindSockActivityAttributes.ContentState {
    TripWindSockActivityAttributes.ContentState(tripState: .starting)
  }

  fileprivate static var headWind: TripWindSockActivityAttributes.ContentState {
    TripWindSockActivityAttributes.ContentState(
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

  fileprivate static var tailWind: TripWindSockActivityAttributes.ContentState {
    TripWindSockActivityAttributes.ContentState(
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
        windDirection:  0.4567,
        windCompassDirection: "N"
      )
    )
  }

  fileprivate static var ended: TripWindSockActivityAttributes.ContentState {
    TripWindSockActivityAttributes.ContentState(
      tripState: .ended,
      duration: .seconds(1000),
      distance: 22.0,
      efficiency: 5.5,
      rangeConsumed: 20.4,
    )
  }
}

#Preview("Trip Live Activity", as: .content, using: TripWindSockActivityAttributes.preview) {
  TripWindSockLiveActivityWidget()
} contentStates: {
  TripWindSockActivityAttributes.ContentState.starting
  TripWindSockActivityAttributes.ContentState.tailWind
  TripWindSockActivityAttributes.ContentState.headWind
  TripWindSockActivityAttributes.ContentState.ended
}
