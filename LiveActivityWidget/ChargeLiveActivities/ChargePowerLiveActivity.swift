@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoSharing
import DokoLiveActivityManager

struct ChargePowerLiveActivity: View, DokoLiveActivityFonts {
  let context: ActivityViewContext<ChargePowerActivityAttributes>

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

  private struct StartingView: View, DokoLiveActivityFonts {
    let context: ActivityViewContext<ChargePowerActivityAttributes>
    @Environment(\.activityFamily) var activityFamily

    var body: some View {
      HStack(alignment: .center) {
        Text("Charge Starting")
          .foregroundStyle(DesignTokens.Color.primary)
          .font(laTitle)
        Spacer()
      }
      .padding()
    }
  }

  private struct ActiveView: View, DokoLiveActivityFonts {
    let context: ActivityViewContext<ChargePowerActivityAttributes>

    @Environment(\.activityFamily) var activityFamily

    @Shared(.appSettings) var appSettings

    var body: some View {
      let measuredPower = context.state.measuredPower

      HStack(alignment: .center) {
        HStack {
          Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 2) {
            if let measuredPower {
              let measuredPower = Measurement(value: measuredPower, unit: UnitPower.kilowatts)
              GridRow(alignment: .lastTextBaseline) {
                Image(systemName: "bolt.circle.fill")
                  .font(laSymbol)
                  .gridColumnAlignment(.leading)
                  .padding(.trailing, laSymbolSpacing)
                Text(String(format: "%5.1f", measuredPower.value))
                  .font(laValue.monospacedDigit())
                  .gridColumnAlignment(.trailing)
                Text(measuredPower.unit.symbol)
                  .font(laUnit)
                  .gridColumnAlignment(.leading)
              }
              .foregroundStyle(DesignTokens.Color.power)
            }
          }
        }
      }
      .padding()
    }
  }

  private struct EndedView: View, DokoLiveActivityFonts {
    let context: ActivityViewContext<ChargePowerActivityAttributes>

    @Environment(\.activityFamily) var activityFamily

    @Shared(.appSettings) var appSettings

    var body: some View {
      let duration = context.state.duration
      let energyAdded = context.state.energy
      let stateOfChargeAdded = context.state.stateOfCharge
      let rangeAdded = context.state.rangeAdded
      let batteryTemperature = context.state.batteryTemperature

      VStack {
        HStack {
          Text("Charge Complete")
            .font(laTitle)
            .foregroundStyle(DesignTokens.Color.primary)
          Spacer()
        }

        HStack {
          Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 2) {
            GridRow(alignment: .lastTextBaseline) {
              Image(systemName: "clock")
                .font(laSymbol)
                .foregroundStyle(DesignTokens.Color.duration)
                .gridColumnAlignment(.leading)
                .padding(.trailing, laSymbolSpacing)
              Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
                .font(laValue.monospacedDigit())
                .foregroundStyle(DesignTokens.Color.duration)
                .gridColumnAlignment(.trailing)
            }

            if let rangeAdded {
              let rangeAdded = Measurement(value: rangeAdded, unit: UnitLength.kilometers)
                .converted(to: appSettings.metric ? .kilometers : .miles)
              GridRow(alignment: .lastTextBaseline) {
                Image(systemName: "road.lanes")
                  .font(laSymbol)
                  .gridColumnAlignment(.leading)
                  .padding(.trailing, laSymbolSpacing)
                Text(String(format: "%+5.1f", rangeAdded.value))
                  .font(laValue.monospacedDigit())
                  .gridColumnAlignment(.trailing)
                Text(rangeAdded.unit.symbol)
                  .font(laUnit)
                  .gridColumnAlignment(.leading)
              }
              .foregroundStyle(DesignTokens.Color.rangeAdded)
            } else if let batteryTemperature {
              let batteryTemperature = Measurement(value: batteryTemperature, unit: UnitTemperature.celsius)
                .converted(to: appSettings.metric ? .celsius : .fahrenheit)
              GridRow(alignment: .lastTextBaseline) {
                Image(systemName: "batteryblock.stack")
                  .font(laSymbol)
                  .gridColumnAlignment(.leading)
                  .padding(.trailing, laSymbolSpacing)
                Text(String(format: "%.0f", batteryTemperature.value))
                  .font(laValue.monospacedDigit())
                  .gridColumnAlignment(.trailing)
                Text(batteryTemperature.unit.symbol)
                  .font(laUnit)
                  .gridColumnAlignment(.leading)
              }
              .foregroundStyle(DesignTokens.Color.batteryTemperature)
            }
          }

          Spacer()

          Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 2) {
            if let stateOfChargeAdded {
              let stateOfChargeAdded = Measurement(value: stateOfChargeAdded, unit: UnitPercent.percent)
              GridRow(alignment: .lastTextBaseline) {
                Image(systemName: "battery.75percent")
                  .font(laSymbol)
                  .gridColumnAlignment(.leading)
                  .padding(.trailing, laSymbolSpacing)
                Text(String(format: "%.0f", stateOfChargeAdded.value))
                  .font(laValue.monospacedDigit())
                  .gridColumnAlignment(.trailing)
                Text(stateOfChargeAdded.unit.symbol)
                  .font(laUnit)
                  .gridColumnAlignment(.leading)
              }
              .foregroundStyle(DesignTokens.Color.stateOfCharge)
            }

            if let energyAdded {
              let energy = Measurement(value: energyAdded, unit: UnitEnergy.kilowattHours)
              GridRow(alignment: .lastTextBaseline) {
                Image(systemName: "bolt")
                  .font(laSymbol)
                  .gridColumnAlignment(.leading)
                  .padding(.trailing, laSymbolSpacing)
                Text(String(format: "%+5.1f", energy.value))
                  .font(laValue.monospacedDigit())
                  .gridColumnAlignment(.trailing)
                Text(energy.unit.symbol)
                  .font(laUnit)
                  .gridColumnAlignment(.leading)
              }
              .foregroundStyle(DesignTokens.Color.energy)
            }
          }
        }
      }
      .padding()
    }
  }
}

extension ChargePowerActivityAttributes {
  fileprivate static var preview: ChargePowerActivityAttributes {
    ChargePowerActivityAttributes()
  }
}

extension ChargePowerActivityAttributes.ContentState {
  fileprivate static var starting: ChargePowerActivityAttributes.ContentState {
    ChargePowerActivityAttributes.ContentState(chargeState: .starting)
  }

  fileprivate static var active: ChargePowerActivityAttributes.ContentState {
    ChargePowerActivityAttributes.ContentState(
      chargeState: .active,
      duration: .seconds(1200),
      measuredPower: 10.4,
      batteryVoltage: 370.3,
      batteryCurrent: 40.3,
      batteryTemperature: 40.3,
      couplerTemperature: 60.3,
    )
  }

  fileprivate static var ended: ChargePowerActivityAttributes.ContentState {
    ChargePowerActivityAttributes.ContentState(
      chargeState: .ended,
      duration: .seconds(1200),
      stateOfCharge: 47.5,
      energy: 65.3,
      rangeAdded: 5.0,
    )
  }
}

#Preview("Charge Power Live Activity", as: .content, using: ChargePowerActivityAttributes.preview) {
  ChargePowerLiveActivityWidget()
} contentStates: {
  ChargePowerActivityAttributes.ContentState.starting
  ChargePowerActivityAttributes.ContentState.active
  ChargePowerActivityAttributes.ContentState.ended
}
