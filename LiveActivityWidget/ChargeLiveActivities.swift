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
      HStack(alignment: .center) {
        DokoWidgetIcon()
        Spacer()
        Text("Charge Active")
          .foregroundStyle(DesignTokens.Color.primary)
      }
      .font(laTitle)
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

  fileprivate static var active: ChargeActivityAttributes.ContentState {
    ChargeActivityAttributes.ContentState(chargeState: .active)
  }

  fileprivate static var ended: ChargeActivityAttributes.ContentState {
    ChargeActivityAttributes.ContentState(chargeState: .ended)
  }
}

#Preview("Charge Live Activity", as: .content, using: ChargeActivityAttributes.preview) {
  ChargeLiveActivityWidget()
} contentStates: {
  ChargeActivityAttributes.ContentState.starting
  ChargeActivityAttributes.ContentState.active
  ChargeActivityAttributes.ContentState.ended
}

