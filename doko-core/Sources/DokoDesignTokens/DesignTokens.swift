import SwiftUI
import UIKit

public enum DesignTokens {

  public enum Color {
    // Core
    public static let primary = SwiftUI.Color.accentColor
    public static let secondary = SwiftUI.Color.secondary
    public static let secondaryText = SwiftUI.Color.secondary
    public static let background = SwiftUI.Color(.systemBackground)
    public static let groupedBackground = SwiftUI.Color(.systemGroupedBackground)
    public static let secondaryGroupedBackground = SwiftUI.Color(.secondarySystemGroupedBackground)
    public static let label = SwiftUI.Color(.label)
    public static let value = SwiftUI.Color(.label)
    public static let progress = SwiftUI.Color.blue

    // Semantic
    public static let alert = SwiftUI.Color.red
    public static let success = SwiftUI.Color.green
    public static let warning = SwiftUI.Color.yellow
    public static let info = SwiftUI.Color.blue

    // Domain-specific
    public static let cool = SwiftUI.Color.blue
    public static let warm = SwiftUI.Color.yellow
    public static let hot = SwiftUI.Color.red
    public static let record = SwiftUI.Color.red
    public static let duration = SwiftUI.Color.yellow
    public static let distance = SwiftUI.Color.blue
    public static let elevation = SwiftUI.Color.green
    public static let tripping = SwiftUI.Color.cyan
    public static let rangeAdded = SwiftUI.Color.green
    public static let rangeUnder = SwiftUI.Color.green
    public static let rangeOver = SwiftUI.Color.red
    public static let charging = SwiftUI.Color.green
    public static let stateOfCharge = SwiftUI.Color.green
    public static let power = SwiftUI.Color.orange
    public static let energy = SwiftUI.Color.orange
    public static let efficiency = SwiftUI.Color.green
    public static let voltage = SwiftUI.Color.purple
    public static let current = SwiftUI.Color.cyan
    public static let weather = SwiftUI.Color.white
    public static let batteryTemperature = SwiftUI.Color.yellow
    public static let couplerTemperature = SwiftUI.Color.red

    // Component backgrounds
    public static let cardBackground = SwiftUI.Color.gray.opacity(Opacity.cardBackground)
  }

  public enum Font {
    public static let largeTitle = SwiftUI.Font.largeTitle
    public static let title = SwiftUI.Font.title
    public static let headline = SwiftUI.Font.headline
    public static let subheadline = SwiftUI.Font.subheadline
    public static let body = SwiftUI.Font.body
    public static let callout = SwiftUI.Font.callout
    public static let caption = SwiftUI.Font.caption

    // Rounded variants for numeric displays
    public static let titleRounded = SwiftUI.Font.title.weight(.bold)
    public static let headlineRounded = SwiftUI.Font.headline.weight(.bold)

    // Medium Live Activity (Dynamic Island expanded / Lock Screen)
    public static let mlaSymbol = SwiftUI.Font.system(size: 18)
    public static let mlaValue = SwiftUI.Font.system(size: 30)
    public static let mlaUnit = SwiftUI.Font.system(size: 16)
    public static let mlaTitle = SwiftUI.Font.system(size: 36)
    public static let mlaSubtitle = SwiftUI.Font.system(size: 30)
    public static let mlaLabel = SwiftUI.Font.system(size: 20)

    // Small Live Activity (Dynamic Island compact / minimal)
    public static let slaSymbol = SwiftUI.Font.system(size: 8)
    public static let slaValue = SwiftUI.Font.system(size: 13)
    public static let slaUnit = SwiftUI.Font.system(size: 7)
    public static let slaTitle = SwiftUI.Font.system(size: 14)
    public static let slaSubtitle = SwiftUI.Font.system(size: 10)
    public static let slaLabel = SwiftUI.Font.system(size: 9)
  }

  public enum Spacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 20
    public static let xl: CGFloat = 30
  }

  public enum CornerRadius {
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 10
    public static let large: CGFloat = 12
  }

  public enum Opacity {
    public static let full: Double = 1.0
    public static let muted: Double = 0.7
    public static let subtle: Double = 0.6
    public static let cardBackground: Double = 0.25
    public static let disabled: Double = 0.4
    public static let hidden: Double = 0.0
  }

  public enum Padding {
    public static let rowVertical: CGFloat = 4
    public static let cardInsets = EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
    public static let cardInsetsWide = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
    public static let listHorizontal: CGFloat = 10
    public static let pickerSpacing: CGFloat = 10
  }

  public enum Grid {
    public static let horizontalSpacing: CGFloat = 8
    public static let verticalSpacing: CGFloat = 8
  }

  public enum WindScale {
    public static let light: Double = 0.4
    public static let moderate: Double = 0.7
    public static let strong: Double = 1.0
  }

  // MARK: - Button Styles

  public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .font(.headline)
        .padding()
        .frame(maxWidth: .infinity)
        .background(SwiftUI.Color.blue)
        .foregroundColor(.white)
        .cornerRadius(CornerRadius.medium)
        .opacity(configuration.isPressed ? Opacity.muted : 1.0)
    }
  }

  public struct DestructiveButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .font(.headline)
        .padding()
        .frame(maxWidth: .infinity)
        .background(SwiftUI.Color.red)
        .foregroundColor(.white)
        .cornerRadius(CornerRadius.medium)
        .opacity(configuration.isPressed ? Opacity.muted : 1.0)
    }
  }

  public struct SecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .font(.headline)
        .padding()
        .frame(maxWidth: .infinity)
        .background(SwiftUI.Color.gray.opacity(0.3))
        .foregroundColor(.primary)
        .cornerRadius(CornerRadius.medium)
        .opacity(configuration.isPressed ? Opacity.muted : 1.0)
    }
  }

  public struct DisabledButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .font(.headline)
        .padding()
        .frame(maxWidth: .infinity)
        .background(SwiftUI.Color.gray.opacity(0.3))
        .foregroundColor(.primary)
        .cornerRadius(CornerRadius.medium)
        .opacity(Opacity.disabled)
    }
  }
}
