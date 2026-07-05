import SwiftUI
import WidgetKit

import DokoLiveActivityManager

public protocol DokoLiveActivityFonts: View {
  var activityFamily: ActivityFamily { get }
}

extension DokoLiveActivityFonts {
  var laSymbol: Font            { activityFamily == .small ? DesignTokens.Font.slaSymbol : DesignTokens.Font.mlaSymbol }
  var laSymbolSpacing: CGFloat  { activityFamily == .small ? DesignTokens.Spacing.xxs : DesignTokens.Spacing.xxs }
  var laValue: Font             { activityFamily == .small ? DesignTokens.Font.slaValue  : DesignTokens.Font.mlaValue  }
  var laUnit: Font              { activityFamily == .small ? DesignTokens.Font.slaUnit   : DesignTokens.Font.mlaUnit   }
  var laTitle: Font             { activityFamily == .small ? DesignTokens.Font.slaTitle  : DesignTokens.Font.mlaTitle  }
  var laLabel: Font             { activityFamily == .small ? DesignTokens.Font.slaLabel  : DesignTokens.Font.mlaLabel  }

  var laIconFrame: Double       { activityFamily == .small ? 16 : 36 }
  var laArrowFrame: Double      { activityFamily == .small ? 36 : 60 }
}
