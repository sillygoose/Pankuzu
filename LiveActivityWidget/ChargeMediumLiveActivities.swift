//@preconcurrency import ActivityKit
//import SwiftUI
//import WidgetKit
//
//import DokoLiveActivityManager
//
//struct MediumChargeLiveActivities: View {
//  let context: ActivityViewContext<ChargeActivityAttributes>
//  
//  var body: some View {
//    switch context.state.chargeState {
//    case .starting:
//      StartingView(context: context)
//    case .active:
//      ActiveView(context: context)
//    case .ended:
//      EndedView(context: context)
//    }
//  }
//  
//  private struct StartingView: View {
//    let context: ActivityViewContext<ChargeActivityAttributes>
//    
//    var body: some View {
//      HStack(alignment: .center) {
//        DokoWidgetIcon()
//        Spacer()
//        Text("Charge Starting")
//          .foregroundStyle(DesignTokens.Color.primary)
//      }
//      .font(DesignTokens.Font.largeTitle)
//      .padding()
//    }
//  }
//  
//  private struct ActiveView: View {
//    let context: ActivityViewContext<ChargeActivityAttributes>
//    
//    var body: some View {
//      let duration = context.state.duration
////      let stateOfCharge = context.state.stateOfCharge
////      let rangeAdded = context.state.rangeAdded
//      let measuredPower = context.state.measuredPower
//      let batteryVoltage = context.state.batteryVoltage
//      let batteryCurrent = context.state.batteryCurrent
//      let batteryTemperature = context.state.batteryTemperature
//      let couplerTemperature = context.state.couplerTemperature
//
//      HStack(alignment: .center) {
//        DokoWidgetIcon()
//        Spacer()
//        
//        Grid(alignment: .leading) {
//          GridRow {
//            Image(systemName: "clock")
//              .gridColumnAlignment(.trailing)
//              .font(DesignTokens.Font.mlaSymbol)
//            Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
//              .gridColumnAlignment(.leading)
//              .font(DesignTokens.Font.mlaValue)
//          }
//          .foregroundStyle(DesignTokens.Color.duration)
//
//          if let batteryTemperature {
//            Spacer()
//            GridRow {
//              Image(systemName: "batteryblock.stack")
//                .font(DesignTokens.Font.mlaSymbol)
//              HStack(alignment: .firstTextBaseline, spacing: 2) {
//                Text(String(format: "%3.0f", batteryTemperature.value))
//                  .font(DesignTokens.Font.mlaValue.monospacedDigit())
//                Text(batteryTemperature.unit.symbol)
//                  .font(DesignTokens.Font.mlaUnit)
//              }
//            }
//            .foregroundStyle(DesignTokens.Color.charging)
//          }
//          if let couplerTemperature {
//            Spacer()
//            GridRow {
//              Image(systemName: "ev.plug.dc.ccs1")
//                .font(DesignTokens.Font.mlaSymbol)
//              HStack(alignment: .firstTextBaseline, spacing: 2) {
//                Text(String(format: "%3.0f", couplerTemperature.value))
//                  .font(DesignTokens.Font.mlaValue.monospacedDigit())
//                Text(couplerTemperature.unit.symbol)
//                  .font(DesignTokens.Font.mlaUnit)
//              }
//            }
//            .foregroundStyle(DesignTokens.Color.charging)
//          }
//        }
//
//        Spacer()
//
//        Grid(alignment: .trailing) {
//          if let batteryVoltage {
//            GridRow {
//              HStack(alignment: .firstTextBaseline, spacing: 2) {
//                Text(String(format: "%5.1f", batteryVoltage.value))
//                  .font(DesignTokens.Font.mlaValue.monospacedDigit())
//                Text(batteryVoltage.unit.symbol)
//                  .font(DesignTokens.Font.mlaUnit)
//              }
//            }
//            .foregroundStyle(DesignTokens.Color.charging)
//          }
//
//          if let batteryCurrent {
//            GridRow {
//              HStack(alignment: .firstTextBaseline, spacing: 2) {
//                Text(String(format: "%5.1f", batteryCurrent.value))
//                  .font(DesignTokens.Font.mlaValue.monospacedDigit())
//                Text(batteryCurrent.unit.symbol)
//                  .font(DesignTokens.Font.mlaUnit)
//              }
//            }
//            .foregroundStyle(DesignTokens.Color.charging)
//          }
//
//          if let measuredPower {
//            Spacer()
//            GridRow {
//              HStack(alignment: .firstTextBaseline, spacing: 2) {
//                Text(String(format: "%5.1f", measuredPower.value))
//                  .gridColumnAlignment(.trailing)
//                  .font(DesignTokens.Font.mlaValue.monospacedDigit())
//                Text(measuredPower.unit.symbol)
//                  .gridColumnAlignment(.leading)
//                  .font(DesignTokens.Font.mlaUnit)
//              }
//            }
//            .foregroundStyle(DesignTokens.Color.power)
//          }
//        }
//      }
//      .padding()
//      .frame(height: 160)
//    }
//  }
//
//  private struct EndedView: View {
//    let context: ActivityViewContext<ChargeActivityAttributes>
//    
//    var body: some View {
//      HStack(alignment: .center) {
//        DokoWidgetIcon()
//        Spacer()
//        Text("Charge Ended")
//          .foregroundStyle(DesignTokens.Color.primary)
//      }
//      .font(DesignTokens.Font.largeTitle)
//      .padding()
//    }
//  }
//}
//
//extension ChargeActivityAttributes {
//  fileprivate static var preview: ChargeActivityAttributes {
//    ChargeActivityAttributes()
//  }
//}
//
//extension ChargeActivityAttributes.ContentState {
//  fileprivate static var starting: ChargeActivityAttributes.ContentState {
//    ChargeActivityAttributes.ContentState(chargeState: .starting)
//  }
//
//  fileprivate static var full: ChargeActivityAttributes.ContentState {
//    ChargeActivityAttributes.ContentState(
//      chargeState: .active,
//      duration: .seconds(1200),
//      stateOfCharge: .init(value: 71.5, unit: .percent),
//      rangeAdded: .init(value: 5.0, unit: .kilometers),
//      measuredPower: .init(value: 10.0, unit: .kilowatts),
//      batteryVoltage: .init(value: 370.3, unit: .volts),
//      batteryCurrent: .init(value: 40.3, unit: .amperes),
//      batteryTemperature: .init(value: 40.3, unit: .celsius),
//      couplerTemperature: .init(value: 60.3, unit: .celsius),
//    )
//  }
//
//  fileprivate static var noRangeAdded: ChargeActivityAttributes.ContentState {
//    ChargeActivityAttributes.ContentState(
//      chargeState: .active,
//      duration: .seconds(1200),
//      stateOfCharge: .init(value: 68.5, unit: .percent),
//      rangeAdded: nil,
//      measuredPower: .init(value: 10.0, unit: .kilowatts)
//    )
//  }
//
//  fileprivate static var noMeasuredPower: ChargeActivityAttributes.ContentState {
//    ChargeActivityAttributes.ContentState(
//      chargeState: .active,
//      duration: .seconds(1200),
//      stateOfCharge: .init(value: 21.5, unit: .percent),
//      rangeAdded: .init(value: 5.0, unit: .kilometers),
//      measuredPower: nil
//    )
//  }
//
//  fileprivate static var minimum: ChargeActivityAttributes.ContentState {
//    ChargeActivityAttributes.ContentState(
//      chargeState: .active,
//      duration: .seconds(1200),
//      stateOfCharge: .init(value: 21.5, unit: .percent),
//      rangeAdded: nil,
//      measuredPower: nil
//    )
//  }
//
//  fileprivate static var ended: ChargeActivityAttributes.ContentState {
//    ChargeActivityAttributes.ContentState(chargeState: .ended)
//  }
//}
//
//#Preview("Charge Live Activity", as: .content, using: ChargeActivityAttributes.preview) {
//  ChargeLiveActivityWidget()
//} contentStates: {
//  ChargeActivityAttributes.ContentState.starting
//  ChargeActivityAttributes.ContentState.full
//  ChargeActivityAttributes.ContentState.minimum
//  ChargeActivityAttributes.ContentState.noRangeAdded
//  ChargeActivityAttributes.ContentState.noMeasuredPower
//  ChargeActivityAttributes.ContentState.ended
//}
//
