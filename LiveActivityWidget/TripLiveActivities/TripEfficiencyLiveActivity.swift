@preconcurrency import ActivityKit
import Charts
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
        EmptyView()
//        EndedView(context: context)
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
      let targetUnit: UnitEnergyEfficiency = appSettings.metric
      ? (appSettings.kWhPer100km ? .kilowattHoursPer100Kilometers : .kilometersPerKilowattHour)
      : .milesPerKilowattHour
      let efficiency = Measurement(value: context.state.efficiency ?? 0.0, unit: UnitEnergyEfficiency.kilometersPerKilowattHour)
        .converted(to: targetUnit)
      let efficiencyFormat = targetUnit == .kilowattHoursPer100Kilometers ? "%.1f" : "%.2f"

      HStack(alignment: .bottom) {
        VStack(alignment: .leading) {
          if let rangeConsumed = context.state.rangeConsumed {
            let rangeConsumedColor = rangeConsumed < 0 ? DesignTokens.Color.rangeOver : DesignTokens.Color.rangeUnder
            let tripRangeConsumed = Measurement(value: rangeConsumed, unit: UnitLength.kilometers)
              .converted(to: appSettings.metric ? .kilometers : .miles)
            HStack(alignment: .bottom, spacing: 2) {
              Text(String(format: "%+.0f", tripRangeConsumed.value))
                .font(laValue.monospacedDigit())
                .foregroundStyle(rangeConsumedColor)
                .gridColumnAlignment(.trailing)
              Text(tripRangeConsumed.unit.symbol)
                .font(laUnit)
                .foregroundStyle(rangeConsumedColor)
                .gridColumnAlignment(.leading)
            }
            Spacer()
          }

          HStack(alignment: .bottom, spacing: 2) {
            Text(String(format: efficiencyFormat, efficiency.value))
              .font(laValue)
            Text(efficiency.unit.symbol)
              .font(laUnit)
          }
        }
        .foregroundStyle(DesignTokens.Color.primary)
        
        EfficiencyChartView(
          points: context.state.efficiencyMovingAverage,
          efficiency: context.state.efficiency ?? 0.0,
          pastEfficiency: context.state.pastEfficiency
        )
      }
      .padding()
    }
  }
  
//  private struct EndedView : View, DokoLiveActivityFonts {
//    let context: ActivityViewContext<TripEfficiencyActivityAttributes>
//    
//    @Environment(\.activityFamily) var activityFamily
//    
//    @Shared(.appSettings) var appSettings
//    
//    var body: some View {
//      let duration = context.state.duration
//      let distance = context.state.distance
//      let energy = context.state.energy
//      let efficiency = context.state.efficiency
//      
//      HStack(alignment: .center) {
//        VStack {
//          HStack {
//            Text("Trip Completed")
//              .foregroundStyle(DesignTokens.Color.primary)
//              .font(laSubtitle)
//            Spacer()
//          }
//          .padding(.bottom, 2)
//          
//          HStack {
//            Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
//              GridRow(alignment: .lastTextBaseline) {
//                Image(systemName: "clock")
//                  .font(laSymbol)
//                  .gridColumnAlignment(.leading)
//                  .padding(.trailing, laSymbolSpacing)
//                Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
//                  .font(laValue.monospacedDigit())
//                  .gridColumnAlignment(.trailing)
//              }
//              .foregroundStyle(DesignTokens.Color.duration)
//              
//              GridRow(alignment: .lastTextBaseline) {
//                let distance = Measurement(value: distance, unit: UnitLength.kilometers)
//                  .converted(to: appSettings.metric ? .kilometers : .miles)
//                Image(systemName: "road.lanes")
//                  .font(laSymbol)
//                  .gridColumnAlignment(.leading)
//                  .padding(.trailing, laSymbolSpacing)
//                Text(String(format: "%5.1f", distance.value))
//                  .font(laValue.monospacedDigit())
//                  .gridColumnAlignment(.trailing)
//                Text(distance.unit.symbol)
//                  .font(laUnit)
//                  .gridColumnAlignment(.leading)
//              }
//              .foregroundStyle(DesignTokens.Color.distance)
//            }
//            
//            Spacer()
//            
//            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 2) {
//              if let energy {
//                let tripEnergy = Measurement(value: -energy, unit: UnitEnergy.kilowattHours)
//                GridRow(alignment: .lastTextBaseline) {
//                  Image(systemName: "bolt.circle.fill")
//                    .font(laSymbol)
//                    .gridColumnAlignment(.leading)
//                    .padding(.trailing, laSymbolSpacing)
//                  Text(String(format: "%.1f", tripEnergy.value))
//                    .font(laValue.monospacedDigit())
//                    .gridColumnAlignment(.trailing)
//                  Text(tripEnergy.unit.symbol)
//                    .font(laUnit)
//                    .gridColumnAlignment(.leading)
//                }
//                .foregroundStyle(DesignTokens.Color.energy)
//              }
//              
//              if let efficiency {
//                let targetUnit: UnitEnergyEfficiency = appSettings.metric
//                ? (appSettings.kWhPer100km ? .kilowattHoursPer100Kilometers : .kilometersPerKilowattHour)
//                : .milesPerKilowattHour
//                let efficiencyFormat = targetUnit == .kilowattHoursPer100Kilometers ? "%5.1f" : "%5.2f"
//                
//                let tripEfficiency = Measurement(value: efficiency, unit: UnitEnergyEfficiency.kilometersPerKilowattHour)
//                  .converted(to: targetUnit)
//                GridRow(alignment: .lastTextBaseline) {
//                  Image(systemName: "ev.charger")
//                    .font(laSymbol)
//                    .gridColumnAlignment(.leading)
//                    .padding(.trailing, laSymbolSpacing)
//                  Text(String(format: efficiencyFormat, tripEfficiency.value))
//                    .font(laValue.monospacedDigit())
//                    .gridColumnAlignment(.trailing)
//                  Text(tripEfficiency.unit.symbol)
//                    .font(laUnit)
//                    .gridColumnAlignment(.leading)
//                }
//                .foregroundStyle(DesignTokens.Color.efficiency)
//              }
//            }
//          }
//        }
//      }
//      .padding()
//    }
//  }
}

private struct EfficiencyChartView: View, DokoLiveActivityFonts {
  let points: [EfficiencyPoint]
  let efficiency: Double
  let pastEfficiency: Double?
  
  @Environment(\.activityFamily) var activityFamily
  @Shared(.appSettings) var appSettings
  
  var body: some View {
    let targetUnit: UnitEnergyEfficiency = appSettings.metric
    ? (appSettings.kWhPer100km ? .kilowattHoursPer100Kilometers : .kilometersPerKilowattHour)
    : .milesPerKilowattHour
    
    let yMax: Double = {
      switch targetUnit {
      case .kilometersPerKilowattHour:
        return 10
      case .kilowattHoursPer100Kilometers:
        return 40
      case .milesPerKilowattHour:
        return 5
      default:
        return 10
      }
    }()
    let yMid = yMax / 2
    
    let domainEnd = points.last?.timestamp ?? Date()
    let domainStart = domainEnd.addingTimeInterval(-15 * 60)

    VStack(spacing: 2) {
      Chart {
        ForEach(points) { point in
          let converted = Measurement(value: point.efficiency, unit: UnitEnergyEfficiency.kilometersPerKilowattHour)
            .converted(to: targetUnit)
          // Negative efficiency is a sentinel for net-regen windows (see TripEfficiency.windowEfficiency);
          // treat it as off-the-chart efficient rather than converting it (kWh/100km is a reciprocal unit,
          // so converting a negative raw value wouldn't reliably land above yMax).
          let displayValue = point.efficiency < 0 ? yMax : min(converted.value, yMax)
          AreaMark(
            x: .value("Time", point.timestamp),
            y: .value("Efficiency", displayValue)
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(
            LinearGradient(
              colors: [Color.green.opacity(0.5), Color.green.opacity(0)],
              startPoint: .top,
              endPoint: .bottom
            )
          )

          LineMark(
            x: .value("Time", point.timestamp),
            y: .value("Efficiency", displayValue)
          )
          .lineStyle(StrokeStyle(lineWidth: laLine))
          .interpolationMethod(.catmullRom)
          .foregroundStyle(.green)
        }
        
        let convertedPastEfficiency = Measurement(value: pastEfficiency ?? efficiency, unit: UnitEnergyEfficiency.kilometersPerKilowattHour)
          .converted(to: targetUnit)
        let pastDisplayValue = max(0, min(convertedPastEfficiency.value, yMax))
        // Reference marker for the prior 15-minute efficiency, anchored to the left edge of the
        // plot (not tied to the first data point's x-position) so it reads as a fixed baseline
        // rather than part of the trend line — large and distinctly colored to stand apart from it.
        PointMark(
          x: .value("Time", domainStart),
          y: .value("Past Efficiency", pastDisplayValue)
        )
        .symbolSize(laMediumPoint)
        .foregroundStyle(DesignTokens.Color.info)
      }
      .chartXScale(domain: domainStart...domainEnd)
      .chartYScale(domain: 0...yMax)
      .chartXAxis(.hidden)
      .chartYAxis {
        AxisMarks(position: .trailing, values: [0, yMid, yMax]) { value in
          let isMid = value.as(Double.self) == yMid
          AxisGridLine(stroke: StrokeStyle(lineWidth: isMid ? laLine : laThinLine))
            .foregroundStyle(isMid ? Color.white.opacity(0.75) : Color.white.opacity(0.35))
          AxisValueLabel {
            if let v = value.as(Double.self) {
              let label: String = v == yMax ? "\(Int(v))+" : v.truncatingRemainder(dividingBy: 1) == 0 ? Int(v).description : String(format: "%.1f", v)
              Text(label)
                .font(laAxisLabel)
                .foregroundStyle(.white)
                .padding(.leading, 6)
            }
          }
        }
      }
      .chartPlotStyle { $0.frame(maxWidth: .infinity, maxHeight: .infinity) }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
  
  fileprivate static var emptyActiveEfficiency: TripEfficiencyActivityAttributes.ContentState {
    return TripEfficiencyActivityAttributes.ContentState(
      tripState: .active,
      efficiency: 5,
      efficiencyMovingAverage: []
    )
  }
  
  fileprivate static var partialActiveEfficiency: TripEfficiencyActivityAttributes.ContentState {
    let now = Date()
    let raw: [(TimeInterval, Double)] = [
      (0,   0.758), (11,  0.836), (21,  1.360), (31,  2.323), (41,  8.862),
      (51,  0.983), (61,  0.676), (71,  1.054), (81,  1.268), (91,  2.769),
      (101, 4.173), (111, 6.772), (122, 5.380), (132, 2.900), (142, 3.908),
      (152, 6.883), (162, 9.745), (172, 4.415), (183, 2.996), (193, 3.741),
      (204, 0.0),   (223, 0.0),   (225, 0.0),   (235, 0.0),   (245, 0.0),
      (256, 3.384), (266, 3.278), (277, 4.887), (288, 4.748), (298, 9.912),
      (308, 12.829),(319, 572.852),(329, 0.0),  (339, 56.773),(350, 0.0),
      (360, 0.0),   (371, 0.0),   (381, 0.0),   (392, 0.0),   (402, 0.0),
      (413, 0.0),   (423, 8.967), (434, 1.277),
    ]
    let points = raw.map { EfficiencyPoint(timestamp: now.addingTimeInterval($0 - 434), efficiency: $1) }
    return TripEfficiencyActivityAttributes.ContentState(
      tripState: .active,
      efficiency: 5,
      efficiencyMovingAverage: points
    )
  }
  
  fileprivate static var activeEfficiency: TripEfficiencyActivityAttributes.ContentState {
    let now = Date()
    // Real trip data. Offsets are seconds from the first sample; last sample (891s) anchored at now.
    let raw: [(TimeInterval, Double)] = [
      (0,   0.758), (11,  0.836), (21,  1.360), (31,  2.323), (41,  8.862),
      (51,  0.983), (61,  0.676), (71,  1.054), (81,  1.268), (91,  2.769),
      (101, 4.173), (111, 6.772), (122, 5.380), (132, 2.900), (142, 3.908),
      (152, 6.883), (162, 9.745), (172, 4.415), (183, 2.996), (193, 3.741),
      (204, 0.0),   (223, 0.0),   (225, 0.0),   (235, 0.0),   (245, 0.0),
      (256, 3.384), (266, 3.278), (277, 4.887), (288, 4.748), (298, 9.912),
      (308, 12.829),(319, 572.852),(329, 0.0),  (339, 56.773),(350, 0.0),
      (360, 0.0),   (371, 0.0),   (381, 0.0),   (392, 0.0),   (402, 0.0),
      (413, 0.0),   (423, 8.967), (434, 1.277), (444, 2.280), (454, 1.794),
      (465, 3.677), (475, 3.638), (486, 4.789), (496, 3.488), (507, 4.812),
      (538, 0.0),   (539, 0.0),   (540, 0.0),   (548, 0.0),   (558, 0.0),
      (569, 0.824), (579, 0.917), (590, 1.004), (601, 1.308), (611, 1.866),
      (621, 3.933), (631, 5.595), (642, 3.602), (652, 3.093), (663, 2.610),
      (673, 4.372), (683, 149.128),(694, 0.0),  (704, 0.0),   (714, 0.0),
      (725, 0.746), (735, 1.099), (745, 1.641), (756, 3.087), (766, 10.983),
      (777, 31.638),(787, 0.0),   (797, 0.0),   (808, 0.0),   (819, 11.211),
      (829, 37.406),(840, 0.0),   (850, 0.0),   (861, 0.0),   (871, 0.0),
      (881, 6.652), (891, 3.623),
    ]
    let points = raw.map { EfficiencyPoint(timestamp: now.addingTimeInterval($0 - 891), efficiency: $1) }
    return TripEfficiencyActivityAttributes.ContentState(
      tripState: .active,
      efficiency: 5,
      efficiencyMovingAverage: points
    )
  }

  fileprivate static var activeEfficiencyWithPast: TripEfficiencyActivityAttributes.ContentState {
    let now = Date()
    let raw: [(TimeInterval, Double)] = [
      (0,   0.758), (11,  0.836), (21,  1.360), (31,  2.323), (41,  8.862),
      (51,  0.983), (61,  0.676), (71,  1.054), (81,  1.268), (91,  2.769),
      (101, 4.173), (111, 6.772), (122, 5.380), (132, 2.900), (142, 3.908),
      (152, 6.883), (162, 9.745), (172, 4.415), (183, 2.996), (193, 3.741),
    ]
    let points = raw.map { EfficiencyPoint(timestamp: now.addingTimeInterval($0 - 193), efficiency: $1) }
    return TripEfficiencyActivityAttributes.ContentState(
      tripState: .active,
      efficiency: 5,
      pastEfficiency: 3.2,
      rangeConsumed: -15,
      efficiencyMovingAverage: points
    )
  }

  fileprivate static var ended: TripEfficiencyActivityAttributes.ContentState {
    TripEfficiencyActivityAttributes.ContentState(
      tripState: .ended,
      duration: .seconds(1000),
      distance: 22.0,
      energy: -4.1,
      efficiency: 5.5,
    )
  }
  
  fileprivate static var endedWithRangeConsumed: TripEfficiencyActivityAttributes.ContentState {
    TripEfficiencyActivityAttributes.ContentState(
      tripState: .ended,
      duration: .seconds(1000),
      distance: 22.0,
      energy: -4.1,
      efficiency: 5.5
    )
  }
}

#Preview("Starting", as: .content, using: TripEfficiencyActivityAttributes.preview) {
  TripEfficiencyLiveActivityWidget()
} contentStates: {
  TripEfficiencyActivityAttributes.ContentState.starting
}

#Preview("Efficiency", as: .content, using: TripEfficiencyActivityAttributes.preview) {
  TripEfficiencyLiveActivityWidget()
} contentStates: {
  TripEfficiencyActivityAttributes.ContentState.emptyActiveEfficiency
  TripEfficiencyActivityAttributes.ContentState.partialActiveEfficiency
  TripEfficiencyActivityAttributes.ContentState.activeEfficiency
  TripEfficiencyActivityAttributes.ContentState.activeEfficiencyWithPast
}

#Preview("Ending", as: .content, using: TripEfficiencyActivityAttributes.preview) {
  TripEfficiencyLiveActivityWidget()
} contentStates: {
  TripEfficiencyActivityAttributes.ContentState.ended
  TripEfficiencyActivityAttributes.ContentState.endedWithRangeConsumed
}
