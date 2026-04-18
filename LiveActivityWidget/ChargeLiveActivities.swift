@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

private protocol ChargeLiveActivityFonts: View {
  var activityFamily: ActivityFamily { get }
}

extension ChargeLiveActivityFonts {
  var laSymbol: Font { activityFamily == .small ? DesignTokens.Font.slaSymbol : DesignTokens.Font.mlaSymbol }
  var laValue: Font  { activityFamily == .small ? DesignTokens.Font.slaValue  : DesignTokens.Font.mlaValue  }
  var laUnit: Font   { activityFamily == .small ? DesignTokens.Font.slaUnit   : DesignTokens.Font.mlaUnit   }
  var laTitle: Font  { activityFamily == .small ? DesignTokens.Font.slaTitle  : DesignTokens.Font.mlaTitle  }
  var laLabel: Font  { activityFamily == .small ? DesignTokens.Font.slaLabel  : DesignTokens.Font.mlaLabel  }
  var laArrowFrame: Double  { activityFamily == .small ? 36 : 60 }
}

struct ChargeLiveActivities: View, ChargeLiveActivityFonts {
  let context: ActivityViewContext<ChargeActivityAttributes>

  @Environment(\.activityFamily) var activityFamily

  var body: some View {
    switch context.state.chargeState {
    case .starting:
      StartingView(context: context)
    case .active:
      ActiveView(context: context)
    case .ended:
      EndedView(context: context)
    }
  }

  private struct StartingView: View, ChargeLiveActivityFonts {
    let context: ActivityViewContext<ChargeActivityAttributes>
    @Environment(\.activityFamily) var activityFamily

    var body: some View {
      HStack(alignment: .center) {
        DokoWidgetIcon()
        Spacer()
        Text("Charge Starting")
          .foregroundStyle(DesignTokens.Color.primary)
      }
      .font(laTitle)
      .padding()
    }
  }

  private struct ActiveView: View, ChargeLiveActivityFonts {
    let context: ActivityViewContext<ChargeActivityAttributes>
    @Environment(\.activityFamily) var activityFamily

    var body: some View {
      let duration = context.state.duration
      //      let stateOfCharge = context.state.stateOfCharge
      //      let rangeAdded = context.state.rangeAdded
      let measuredPower = context.state.measuredPower
      let batteryVoltage = context.state.batteryVoltage
      let batteryCurrent = context.state.batteryCurrent
      let batteryTemperature = context.state.batteryTemperature
      let couplerTemperature = context.state.couplerTemperature

      HStack(alignment: .center) {
        DokoWidgetIcon()
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
            Color.clear.frame(width: 0)
          }
          if let batteryTemperature {
            GridRow(alignment: .lastTextBaseline) {
              Image(systemName: "batteryblock.stack")
                .font(laSymbol)
                .foregroundStyle(DesignTokens.Color.distance)
                .gridColumnAlignment(.leading)
              Text(String(format: "%3.0f", batteryTemperature.value))
                .font(laValue.monospacedDigit())
                .foregroundStyle(DesignTokens.Color.vbatteryTemperature)
                .gridColumnAlignment(.trailing)
              Text(batteryTemperature.unit.symbol)
                .font(laUnit)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.leading)
            }
          }
          if let couplerTemperature {
            GridRow(alignment: .lastTextBaseline) {
              Image(systemName: "ev.plug.dc.ccs1")
                .font(laSymbol)
                .foregroundStyle(DesignTokens.Color.elevation)
                .gridColumnAlignment(.leading)
              Text(String(format: "%3.0f", couplerTemperature.value))
                .font(laValue.monospacedDigit())
                .foregroundStyle(DesignTokens.Color.couplerTemperature)
                .gridColumnAlignment(.trailing)
              Text(couplerTemperature.unit.symbol)
                .font(laUnit)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.leading)
            }
          }
        }
        Spacer()
        Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
          if let batteryVoltage {
            GridRow(alignment: .lastTextBaseline) {
              //              Image(systemName: "mountain.2")
              //                .font(laSymbol)
              //                .foregroundStyle(DesignTokens.Color.elevation)
              //                .gridColumnAlignment(.leading)
              Text(String(format: "%5.1f", batteryVoltage.value))
                .font(laValue.monospacedDigit())
                .foregroundStyle(DesignTokens.Color.voltage)
                .gridColumnAlignment(.trailing)
              Text(batteryVoltage.unit.symbol)
                .font(laUnit)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.leading)
            }
          }
          if let batteryCurrent {
            GridRow(alignment: .lastTextBaseline) {
              Text(String(format: "%4.1f", batteryCurrent.value))
                .font(laValue.monospacedDigit())
                .foregroundStyle(DesignTokens.Color.current)
                .gridColumnAlignment(.trailing)
              Text(batteryCurrent.unit.symbol)
                .font(laUnit)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.leading)
            }
          }
          if let measuredPower {
            GridRow(alignment: .lastTextBaseline) {
              Text(String(format: "%4.1f", measuredPower.value))
                .font(laValue.monospacedDigit())
                .foregroundStyle(DesignTokens.Color.power)
                .gridColumnAlignment(.trailing)
              Text(measuredPower.unit.symbol)
                .font(laUnit)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.leading)
            }
          }
        }
      }
      .padding()
    }
  }

  private struct EndedView: View, ChargeLiveActivityFonts {
    let context: ActivityViewContext<ChargeActivityAttributes>
    @Environment(\.activityFamily) var activityFamily

    var body: some View {
      HStack(alignment: .center) {
        DokoWidgetIcon()
        Spacer()
        Text("Charge Ending")
          .foregroundStyle(DesignTokens.Color.primary)
      }
      .font(laTitle)
      .padding()
    }
  }
}

extension ChargeActivityAttributes {
  fileprivate static var preview: ChargeActivityAttributes {
    ChargeActivityAttributes()
  }
}

extension ChargeActivityAttributes.ContentState {
  fileprivate static var starting: ChargeActivityAttributes.ContentState {
    ChargeActivityAttributes.ContentState(chargeState: .starting)
  }

  fileprivate static var full: ChargeActivityAttributes.ContentState {
    ChargeActivityAttributes.ContentState(
      chargeState: .active,
      duration: .seconds(1200),
      stateOfCharge: .init(value: 71.5, unit: .percent),
      rangeAdded: .init(value: 5.0, unit: .kilometers),
      measuredPower: .init(value: 10.0, unit: .kilowatts),
      batteryVoltage: .init(value: 370.3, unit: .volts),
      batteryCurrent: .init(value: 40.3, unit: .amperes),
      batteryTemperature: .init(value: 40.3, unit: .celsius),
      couplerTemperature: .init(value: 60.3, unit: .celsius),
    )
  }

  fileprivate static var ended: ChargeActivityAttributes.ContentState {
    ChargeActivityAttributes.ContentState(chargeState: .ended)
  }
}

#Preview("Charge Live Activity", as: .content, using: ChargeActivityAttributes.preview) {
  ChargeLiveActivityWidget()
} contentStates: {
  ChargeActivityAttributes.ContentState.starting
  ChargeActivityAttributes.ContentState.full
  ChargeActivityAttributes.ContentState.ended
}

