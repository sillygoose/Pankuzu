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
    public static let distance = SwiftUI.Color.blue
    public static let elevation = SwiftUI.Color.green
    public static let tripping = SwiftUI.Color.cyan
    public static let rangeUnder = SwiftUI.Color.green
    public static let rangeOver = SwiftUI.Color.red
    public static let charging = SwiftUI.Color.green
    public static let power = SwiftUI.Color.red
    public static let energy = SwiftUI.Color.orange
    public static let efficiency = SwiftUI.Color.green
    public static let voltage = SwiftUI.Color.purple
    public static let current = SwiftUI.Color.cyan
    public static let weather = SwiftUI.Color.white
    public static let vbatteryTemperature = SwiftUI.Color.yellow
    public static let couplerTemperature = SwiftUI.Color.red
  }
  
  public enum Font {
    public static let largeTitle = SwiftUI.Font.largeTitle
    public static let title = SwiftUI.Font.title
    public static let headline = SwiftUI.Font.headline
    public static let body = SwiftUI.Font.subheadline
    public static let caption = SwiftUI.Font.caption

    public static let mlaSymbol = SwiftUI.Font.system(size: 20)
    public static let mlaValue = SwiftUI.Font.system(size: 32)
    public static let mlaUnit = SwiftUI.Font.system(size: 16)
    public static let mlaTitle = SwiftUI.Font.system(size: 36)
    public static let mlaLabel = SwiftUI.Font.system(size: 20)

    public static let slaSymbol = SwiftUI.Font.system(size: 10)
    public static let slaValue = SwiftUI.Font.system(size: 16)
    public static let slaUnit = SwiftUI.Font.system(size: 8)
    public static let slaTitle = SwiftUI.Font.system(size: 24)
    public static let slaLabel = SwiftUI.Font.system(size: 10)
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
