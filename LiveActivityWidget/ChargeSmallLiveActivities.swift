//
//@preconcurrency import ActivityKit
//import SwiftUI
//import WidgetKit
//
//import DokoLiveActivityManager
//
//struct SmallChargeLiveActivities: View {
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
//      .font(DesignTokens.Font.title)
//      .padding()
//    }
//  }
//
////  private struct ActiveView: View {
////    let context: ActivityViewContext<ChargeActivityAttributes>
////
////    var body: some View {
////      let duration = context.state.duration
////      let batteryTemperature = context.state.batteryTemperature
////      let couplerTemperature = context.state.couplerTemperature
////      let batteryVoltage = context.state.batteryVoltage
////      let batteryCurrent = context.state.batteryCurrent
////      let measuredPower = context.state.measuredPower
////
////      HStack(alignment: .center) {
////        DokoWidgetIcon()
////        Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
////          GridRow {
////            Image(systemName: "clock")
////              .font(DesignTokens.Font.caption)
////              .foregroundStyle(DesignTokens.Color.duration)
////              .gridColumnAlignment(.leading)
////            Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
////              .font(DesignTokens.Font.headline.monospacedDigit())
////              .foregroundStyle(DesignTokens.Color.duration)
////              .gridColumnAlignment(.trailing)
////            Color.clear.frame(width: 0)
////          }
////          if let batteryTemperature {
////            Spacer()
////            GridRow(alignment: .lastTextBaseline) {
////              Image(systemName: "batteryblock.stack")
////                .font(DesignTokens.Font.caption)
////                .foregroundStyle(DesignTokens.Color.primary)
////                .gridColumnAlignment(.leading)
////              Text(String(format: "%4.0f", batteryTemperature.value))
////                .font(DesignTokens.Font.headline.monospacedDigit())
////                .foregroundStyle(DesignTokens.Color.primary)
////                .gridColumnAlignment(.trailing)
////              Text(batteryTemperature.unit.symbol)
////                .font(DesignTokens.Font.caption)
////                .foregroundStyle(.secondary)
////                .gridColumnAlignment(.leading)
////            }
////          }
////          if let couplerTemperature {
////            Spacer()
////            GridRow(alignment: .lastTextBaseline) {
////              Image(systemName: "ev.plug.dc.ccs1")
////                .font(DesignTokens.Font.caption)
////                .foregroundStyle(DesignTokens.Color.primary)
////                .gridColumnAlignment(.leading)
////              Text(String(format: "%3.0f", couplerTemperature.value))
////                .font(DesignTokens.Font.headline.monospacedDigit())
////                .foregroundStyle(DesignTokens.Color.primary)
////                .gridColumnAlignment(.trailing)
////              Text(couplerTemperature.unit.symbol)
////                .font(DesignTokens.Font.caption)
////                .foregroundStyle(.secondary)
////                .gridColumnAlignment(.leading)
////            }
////          }
////        }
////        Spacer()
////        Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
////          GridRow {
////            if let batteryVoltage {
////              GridRow(alignment: .lastTextBaseline) {
////                Image(systemName: "bolt")
////                  .font(DesignTokens.Font.caption)
////                  .foregroundStyle(DesignTokens.Color.primary)
////                  .gridColumnAlignment(.leading)
////                Text(String(format: "%5.1f", batteryVoltage.value))
////                  .font(DesignTokens.Font.headline.monospacedDigit())
////                  .foregroundStyle(DesignTokens.Color.primary)
////                  .gridColumnAlignment(.trailing)
////                Text(batteryVoltage.unit.symbol)
////                  .font(DesignTokens.Font.caption)
////                  .foregroundStyle(.secondary)
////                  .gridColumnAlignment(.leading)
////              }
////            }
////            if let batteryCurrent {
////              Spacer()
////              GridRow(alignment: .lastTextBaseline) {
////                Image(systemName: "directcurrent")
////                  .font(DesignTokens.Font.caption)
////                  .foregroundStyle(DesignTokens.Color.primary)
////                  .gridColumnAlignment(.leading)
////                Text(String(format: "%5.1f", batteryCurrent.value))
////                  .font(DesignTokens.Font.headline.monospacedDigit())
////                  .foregroundStyle(DesignTokens.Color.primary)
////                  .gridColumnAlignment(.trailing)
////                Text(batteryCurrent.unit.symbol)
////                  .font(DesignTokens.Font.caption)
////                  .foregroundStyle(.secondary)
////                  .gridColumnAlignment(.leading)
////              }
////            }
////            if let measuredPower {
////              Spacer()
////              GridRow(alignment: .lastTextBaseline) {
////                Image(systemName: "bolt.car")
////                  .font(DesignTokens.Font.caption)
////                  .foregroundStyle(DesignTokens.Color.primary)
////                  .gridColumnAlignment(.leading)
////                Text(String(format: "%5.1f", measuredPower.value))
////                  .font(DesignTokens.Font.headline.monospacedDigit())
////                  .foregroundStyle(DesignTokens.Color.primary)
////                  .gridColumnAlignment(.trailing)
////                Text(measuredPower.unit.symbol)
////                  .font(DesignTokens.Font.caption)
////                  .foregroundStyle(.secondary)
////                  .gridColumnAlignment(.leading)
////              }
////            }
////          }
////        }
////      }
////      .font(DesignTokens.Font.title)
////      .padding()
////    }
////  }
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
//              .font(DesignTokens.Font.slaSymbol)
//            Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
//              .gridColumnAlignment(.leading)
//              .font(DesignTokens.Font.slaValue)
//          }
//          .foregroundStyle(DesignTokens.Color.duration)
//
//          if let batteryTemperature {
////            Spacer()
//            GridRow {
//              Image(systemName: "batteryblock.stack")
//                .font(DesignTokens.Font.slaSymbol)
//              HStack(alignment: .firstTextBaseline, spacing: 2) {
//                Text(String(format: "%3.0f", batteryTemperature.value))
//                  .font(DesignTokens.Font.slaValue.monospacedDigit())
//                Text(batteryTemperature.unit.symbol)
//                  .font(DesignTokens.Font.slaUnit)
//              }
//            }
//            .foregroundStyle(DesignTokens.Color.charging)
//          }
//          if let couplerTemperature {
////            Spacer()
//            GridRow {
//              Image(systemName: "ev.plug.dc.ccs1")
//                .font(DesignTokens.Font.slaSymbol)
//              HStack(alignment: .firstTextBaseline, spacing: 2) {
//                Text(String(format: "%3.0f", couplerTemperature.value))
//                  .font(DesignTokens.Font.slaValue.monospacedDigit())
//                Text(couplerTemperature.unit.symbol)
//                  .font(DesignTokens.Font.slaUnit)
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
//                  .font(DesignTokens.Font.slaValue.monospacedDigit())
//                Text(batteryVoltage.unit.symbol)
//                  .font(DesignTokens.Font.slaUnit)
//              }
//            }
//            .foregroundStyle(DesignTokens.Color.charging)
//          }
//
//          if let batteryCurrent {
//            GridRow {
//              HStack(alignment: .firstTextBaseline, spacing: 2) {
//                Text(String(format: "%5.1f", batteryCurrent.value))
//                  .font(DesignTokens.Font.slaValue.monospacedDigit())
//                Text(batteryCurrent.unit.symbol)
//                  .font(DesignTokens.Font.slaUnit)
//              }
//            }
//            .foregroundStyle(DesignTokens.Color.charging)
//          }
//
//          if let measuredPower {
////            Spacer()
//            GridRow {
//              HStack(alignment: .firstTextBaseline, spacing: 2) {
//                Text(String(format: "%5.1f", measuredPower.value))
//                  .gridColumnAlignment(.trailing)
//                  .font(DesignTokens.Font.slaValue.monospacedDigit())
//                Text(measuredPower.unit.symbol)
//                  .gridColumnAlignment(.leading)
//                  .font(DesignTokens.Font.slaUnit)
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
//      .font(DesignTokens.Font.title) //### mlaTitle/slaTitle
//      .padding()
//    }
//  }
//}
