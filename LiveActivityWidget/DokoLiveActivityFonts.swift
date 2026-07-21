import SwiftUI
import WidgetKit

import DokoLiveActivityManager

public protocol DokoLiveActivityFonts: View {
  var activityFamily: ActivityFamily { get }
}

extension DokoLiveActivityFonts {
  var laSymbol: Font            { activityFamily == .small ? DesignTokens.Font.slaSymbol    : DesignTokens.Font.mlaSymbol     }
  var laSymbolSpacing: CGFloat  { activityFamily == .small ? DesignTokens.Spacing.xxs       : DesignTokens.Spacing.sm         }
  var laValue: Font             { activityFamily == .small ? DesignTokens.Font.slaValue     : DesignTokens.Font.mlaValue      }
  var laUnit: Font              { activityFamily == .small ? DesignTokens.Font.slaUnit      : DesignTokens.Font.mlaUnit       }
  var laTitle: Font             { activityFamily == .small ? DesignTokens.Font.slaTitle     : DesignTokens.Font.mlaTitle      }
  var laSubtitle: Font          { activityFamily == .small ? DesignTokens.Font.slaSubtitle  : DesignTokens.Font.mlaSubtitle   }
  var laLabel: Font             { activityFamily == .small ? DesignTokens.Font.slaLabel     : DesignTokens.Font.mlaLabel      }

  var laAxisLabel: Font         { activityFamily == .small ? DesignTokens.Font.slaAxisLabel : DesignTokens.Font.mlaAxisLabel  }
  
  var laThinLine: CGFloat       { activityFamily == .small ? DesignTokens.LineWidth.slaThinLine : DesignTokens.LineWidth.mlaThinLine  }
  var laLine: CGFloat           { activityFamily == .small ? DesignTokens.LineWidth.slaLine : DesignTokens.LineWidth.mlaLine  }
  var laThickLine: CGFloat      { activityFamily == .small ? DesignTokens.LineWidth.slaThickLine : DesignTokens.LineWidth.mlaThickLine  }

  var laSmallPoint: CGFloat     { activityFamily == .small ? DesignTokens.PointSize.slaSmallPoint : DesignTokens.PointSize.mlaSmallPoint  }
  var laMediumPoint: CGFloat    { activityFamily == .small ? DesignTokens.PointSize.slaMediumPoint : DesignTokens.PointSize.mlaMediumPoint  }
  var laLargePoint: CGFloat     { activityFamily == .small ? DesignTokens.PointSize.slaLargePoint : DesignTokens.PointSize.mlaLargePoint  }

  var laIconFrame: Double       { activityFamily == .small ? 16 : 36 }
  var laArrowFrame: Double      { activityFamily == .small ? 36 : 60 }
}
