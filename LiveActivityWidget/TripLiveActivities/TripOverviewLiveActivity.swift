@preconcurrency import ActivityKit
import Charts
import SwiftUI
import WidgetKit

import DokoSharing
import DokoLiveActivityManager

struct TripOverviewLiveActivity: View, DokoLiveActivityFonts {
  let context: ActivityViewContext<TripOverviewActivityAttributes>
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
    let context: ActivityViewContext<TripOverviewActivityAttributes>
    
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
    let context: ActivityViewContext<TripOverviewActivityAttributes>
    
    @Environment(\.activityFamily) var activityFamily
    
    @Shared(.appSettings) var appSettings
    
    var body: some View {
      let distance = context.state.distance
      
      HStack(alignment: .center) {
        Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
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
          
          if let rawEfficiency = context.state.efficiency {
            let targetUnit: UnitEnergyEfficiency = appSettings.metric
            ? (appSettings.kWhPer100km ? .kilowattHoursPer100Kilometers : .kilometersPerKilowattHour)
            : .milesPerKilowattHour
            let efficiencyFormat = targetUnit == .kilowattHoursPer100Kilometers ? "%.1f" : "%.2f"

            let efficiency = Measurement(value: rawEfficiency, unit: UnitEnergyEfficiency.kilometersPerKilowattHour)
              .converted(to: targetUnit)

            GridRow(alignment: .lastTextBaseline) {
              Image(systemName: "ev.charger")
                .font(laSymbol)
                .gridColumnAlignment(.leading)
                .padding(.trailing, laSymbolSpacing)
              Text(String(format: efficiencyFormat, efficiency.value))
                .font(laValue.monospacedDigit())
                .gridColumnAlignment(.trailing)
              Text(efficiency.unit.symbol)
                .font(laUnit)
                .gridColumnAlignment(.leading)
            }
            .foregroundStyle(DesignTokens.Color.tripping)
          }
          
          if let rawElevation = context.state.elevation {
            let elevation = Measurement(value: rawElevation, unit: UnitLength.meters)
              .converted(to: appSettings.metric ? .meters : .feet)
            
            GridRow(alignment: .lastTextBaseline) {
              Image(systemName: "mountain.2")
                .font(laSymbol)
                .gridColumnAlignment(.leading)
                .padding(.trailing, laSymbolSpacing)
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
        if let windSock = context.state.windSock {
          WindSockChartView(windSock: windSock)
        }
      }
      .padding()
    }
  }
  
  private struct EndedView : View, DokoLiveActivityFonts {
    let context: ActivityViewContext<TripOverviewActivityAttributes>
    
    @Environment(\.activityFamily) var activityFamily
    
    @Shared(.appSettings) var appSettings
    
    var body: some View {
      let duration = context.state.duration
      let distance = context.state.distance
      let energy = context.state.energy
      let efficiency = context.state.efficiency
      
      HStack(alignment: .center) {
        VStack {
          HStack {
            Text("Trip Completed")
              .foregroundStyle(DesignTokens.Color.primary)
              .font(laSubtitle)
            Spacer()
          }
          .padding(.bottom, 2)
          
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
                let targetUnit: UnitEnergyEfficiency = appSettings.metric
                ? (appSettings.kWhPer100km ? .kilowattHoursPer100Kilometers : .kilometersPerKilowattHour)
                : .milesPerKilowattHour
                let efficiencyFormat = targetUnit == .kilowattHoursPer100Kilometers ? "%5.1f" : "%5.2f"
                
                let tripEfficiency = Measurement(value: efficiency, unit: UnitEnergyEfficiency.kilometersPerKilowattHour)
                  .converted(to: targetUnit)
                GridRow(alignment: .lastTextBaseline) {
                  Image(systemName: "ev.charger")
                    .font(laSymbol)
                    .gridColumnAlignment(.leading)
                    .padding(.trailing, laSymbolSpacing)
                  Text(String(format: efficiencyFormat, tripEfficiency.value))
                    .font(laValue.monospacedDigit())
                    .gridColumnAlignment(.trailing)
                  Text(tripEfficiency.unit.symbol)
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

  private struct WindSockChartView: View, DokoLiveActivityFonts {
    let windSock: WindSock
    
    @Environment(\.activityFamily) var activityFamily
    
    @Shared(.appSettings) var appSettings
    
    var relativeDirection: Double { windSock.windDirection - windSock.course }
    
    var body: some View {
      let headWindScale: Double = windSock.windSpeed < 10 ? DesignTokens.WindScale.light : windSock.windSpeed < 20 ? DesignTokens.WindScale.moderate : DesignTokens.WindScale.strong
      
      let temperature = Measurement(value: windSock.temperature, unit: UnitTemperature.celsius)
        .converted(to: appSettings.metric ? .celsius : .fahrenheit)
      let windSpeed = Measurement(value: windSock.windSpeed, unit: UnitSpeed.kilometersPerHour)
        .converted(to: appSettings.metric ? .kilometersPerHour : .milesPerHour)
      
      VStack(spacing: 2) {
        HStack(spacing: 4) {
          Image(systemName: windSock.conditions)
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
        
        Text("\(windSock.windCompassDirection), \(windSpeed.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))))")
          .font(laLabel)
      }
      .font(.caption)
      .foregroundStyle(DesignTokens.Color.weather)
    }
  }
}

extension TripOverviewActivityAttributes {
  fileprivate static var preview: TripOverviewActivityAttributes {
    TripOverviewActivityAttributes()
  }
}

extension TripOverviewActivityAttributes.ContentState {
  fileprivate static var starting: TripOverviewActivityAttributes.ContentState {
    TripOverviewActivityAttributes.ContentState(tripState: .starting)
  }
  
 
  fileprivate static var headWind: TripOverviewActivityAttributes.ContentState {
    TripOverviewActivityAttributes.ContentState(
      tripState: .active,
      duration: .seconds(1000),
      distance: 22.0,
      efficiency: 4.5,
      elevation: 2322.5,
      rangeConsumed: 26.4,
      windSock: WindSock(
        course: 90,
        temperature: 16,
        conditions: "sun.snow",
        windSpeed: 125,
        windDirection: 90,
        windCompassDirection: "S"
      )
    )
  }
  
  fileprivate static var tailWind: TripOverviewActivityAttributes.ContentState {
    TripOverviewActivityAttributes.ContentState(
      tripState: .active,
      duration: .seconds(1000),
      distance: 22.0,
      elevation: 4322.5,
      rangeConsumed: 20.4,
      windSock: WindSock(
        course: 180,
        temperature: 16.678,
        conditions: "cloud.drizzle.fill",
        windSpeed: 20.12345,
        windDirection:  0.4567,
        windCompassDirection: "N"
      )
    )
  }
  
  fileprivate static var ended: TripOverviewActivityAttributes.ContentState {
    TripOverviewActivityAttributes.ContentState(
      tripState: .ended,
      duration: .seconds(1000),
      distance: 22.0,
      energy: -4.1,
      efficiency: 5.5,
    )
  }
  
  fileprivate static var endedWithRangeConsumed: TripOverviewActivityAttributes.ContentState {
    TripOverviewActivityAttributes.ContentState(
      tripState: .ended,
      duration: .seconds(1000),
      distance: 22.0,
      energy: -4.1,
      efficiency: 5.5,
      rangeConsumed: 20.4,
    )
  }
}

#Preview("Starting", as: .content, using: TripOverviewActivityAttributes.preview) {
  TripOverviewLiveActivityWidget()
} contentStates: {
  TripOverviewActivityAttributes.ContentState.starting
}

#Preview("WindSock", as: .content, using: TripOverviewActivityAttributes.preview) {
  TripOverviewLiveActivityWidget()
} contentStates: {
  TripOverviewActivityAttributes.ContentState.tailWind
  TripOverviewActivityAttributes.ContentState.headWind
}

#Preview("Ending", as: .content, using: TripOverviewActivityAttributes.preview) {
  TripOverviewLiveActivityWidget()
} contentStates: {
  TripOverviewActivityAttributes.ContentState.ended
  TripOverviewActivityAttributes.ContentState.endedWithRangeConsumed
}
