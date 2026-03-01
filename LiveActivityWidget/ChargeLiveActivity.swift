@preconcurrency import ActivityKit
import SwiftUI
import WidgetKit

import DokoLiveActivityManager

struct ChargeLockScreen: View {
  let context: ActivityViewContext<ChargeActivityAttributes>

  var body: some View {
    switch context.state.chargeState {
    case .starting:
      ChargeStartingView()
    case .active:
      ChargeActiveView(
        duration: context.state.duration,
        stateOfCharge: context.state.stateOfCharge,
        rangeAdded: context.state.rangeAdded,
        measuredPower: context.state.measuredPower
      )
    case .ended:
      ChargeEndedView()
    }
  }
}

private struct ChargeStartingView: View {
  var body: some View {
    HStack(alignment: .center) {
      Image(systemName: "ev.charger")
        .foregroundStyle(DesignTokens.Color.charging)
      Spacer()
      Text("Charge Started")
        .foregroundStyle(DesignTokens.Color.primary)
    }
    .font(DesignTokens.Font.largeTitle)
    .padding()
  }
}

struct ChargeActiveView: View {
  let duration: Duration
  let stateOfCharge: Measurement<UnitPercent>
  let rangeAdded: Measurement<UnitLength>?
  let measuredPower: Measurement<UnitPower>?

  var body: some View {
    HStack(alignment: .center) {
      Grid(alignment: .leading) {
        GridRow {
          Image(systemName: "clock")
            .gridColumnAlignment(.trailing)
            .font(DesignTokens.Font.laSymbol)
          Text(duration.formatted(.time(pattern: .hourMinute(padHourToLength: 1))))
            .gridColumnAlignment(.leading)
            .font(DesignTokens.Font.laValue)
        }
        .foregroundStyle(DesignTokens.Color.duration)

        if let rangeAdded {
          Spacer()
          GridRow {
            Image(systemName: "road.lanes")
              .font(DesignTokens.Font.laSymbol)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
              Text(String(format: "+%.0f", rangeAdded.value))
                .font(DesignTokens.Font.laValue)
              Text(rangeAdded.unit.symbol)
                .font(DesignTokens.Font.laUnit)
            }
          }
          .foregroundStyle(DesignTokens.Color.charging)
        }
      }

      Spacer()

      Grid(alignment: .trailing) {
        GridRow {
          HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(String(format: "%.0f", stateOfCharge.value))
              .gridColumnAlignment(.trailing)
              .font(DesignTokens.Font.laValue)
            Text(stateOfCharge.unit.symbol)
              .gridColumnAlignment(.leading)
              .font(DesignTokens.Font.laUnit)
          }
          Image(systemName: "battery.100.bolt")
            .gridColumnAlignment(.leading)
            .font(DesignTokens.Font.laSymbol)
        }
        .foregroundStyle(DesignTokens.Color.charging)
        
        if let measuredPower {
          Spacer()
          GridRow {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
              Text(String(format: "%.0f", measuredPower.value))
                .gridColumnAlignment(.trailing)
                .font(DesignTokens.Font.laValue)
              Text(measuredPower.unit.symbol)
                .gridColumnAlignment(.leading)
                .font(DesignTokens.Font.laUnit)
            }
            Image(systemName: "bolt.fill")
              .font(DesignTokens.Font.laSymbol)
          }
          .foregroundStyle(DesignTokens.Color.power)
        }
      }
    }
    .padding()
    .frame(height: 160)
  }
}

struct ChargeEndedView: View {
  var body: some View {
    HStack(alignment: .center) {
      Image(systemName: "ev.charger")
        .foregroundStyle(DesignTokens.Color.charging)
      Spacer()
      Text("Charge Ended")
        .foregroundStyle(DesignTokens.Color.primary)
    }
    .font(DesignTokens.Font.largeTitle)
    .padding()
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
      measuredPower: .init(value: 10.0, unit: .kilowatts)
    )
  }

  fileprivate static var noRangeAdded: ChargeActivityAttributes.ContentState {
    ChargeActivityAttributes.ContentState(
      chargeState: .active,
      duration: .seconds(1200),
      stateOfCharge: .init(value: 68.5, unit: .percent),
      rangeAdded: nil,
      measuredPower: .init(value: 10.0, unit: .kilowatts)
    )
  }

  fileprivate static var noMeasuredPower: ChargeActivityAttributes.ContentState {
    ChargeActivityAttributes.ContentState(
      chargeState: .active,
      duration: .seconds(1200),
      stateOfCharge: .init(value: 21.5, unit: .percent),
      rangeAdded: .init(value: 5.0, unit: .kilometers),
      measuredPower: nil
    )
  }

  fileprivate static var minimum: ChargeActivityAttributes.ContentState {
    ChargeActivityAttributes.ContentState(
      chargeState: .active,
      duration: .seconds(1200),
      stateOfCharge: .init(value: 21.5, unit: .percent),
      rangeAdded: nil,
      measuredPower: nil
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
  ChargeActivityAttributes.ContentState.minimum
  ChargeActivityAttributes.ContentState.noRangeAdded
  ChargeActivityAttributes.ContentState.noMeasuredPower
  ChargeActivityAttributes.ContentState.ended
}

