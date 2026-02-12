import SwiftUI
import UIKit

public enum DesignTokens {

  public enum Color {
    // Core
    public static let primary = SwiftUI.Color.accentColor
    public static let secondary = SwiftUI.Color.secondary
    public static let background = SwiftUI.Color(UIColor.systemBackground)
    public static let groupedBackground = SwiftUI.Color(UIColor.systemGroupedBackground)
    public static let secondaryGroupedBackground = SwiftUI.Color(UIColor.secondarySystemGroupedBackground)
    public static let label = SwiftUI.Color(UIColor.label)

    // Semantic
    public static let alert = SwiftUI.Color.red
    public static let success = SwiftUI.Color.green
    public static let warning = SwiftUI.Color.yellow
    public static let info = SwiftUI.Color.blue

    // Domain-specific
    public static let record = SwiftUI.Color.red
    public static let duration = SwiftUI.Color.yellow
    public static let tripping = SwiftUI.Color.cyan
    public static let rangeUnder = SwiftUI.Color.green
    public static let rangeOver = SwiftUI.Color.red
    public static let charging = SwiftUI.Color.green
    public static let power = SwiftUI.Color.orange

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
