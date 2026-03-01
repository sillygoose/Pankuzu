import SwiftUI

public enum DesignTokens {
  
  public enum Color {
    public static let primary = SwiftUI.Color.accentColor
    public static let secondaryText = SwiftUI.Color.secondary
    public static let background = SwiftUI.Color(.systemBackground)
    public static let progress = SwiftUI.Color.blue
    public static let alert = SwiftUI.Color.red

    public static let record = SwiftUI.Color.red

    public static let duration = SwiftUI.Color.yellow
    public static let tripping = SwiftUI.Color.cyan
    public static let rangeUnder = SwiftUI.Color.green
    public static let rangeOver = SwiftUI.Color.red
    public static let charging = SwiftUI.Color.green
    public static let power = SwiftUI.Color.orange
  }
  
  public enum Font {
    public static let largeTitle = SwiftUI.Font.largeTitle
    public static let title = SwiftUI.Font.headline
    public static let body = SwiftUI.Font.subheadline
    public static let caption = SwiftUI.Font.caption

    public static let laSymbol = SwiftUI.Font.system(size: 25)
    public static let laValue = SwiftUI.Font.system(size: 44)
    public static let laUnit = SwiftUI.Font.system(size: 25)

  }
  
  public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
  }
  
  public enum CornerRadius {
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
  }

  public enum WindScale {
    public static let light: Double = 0.4
    public static let moderate: Double = 0.7
    public static let strong: Double = 1.0
  }
}
