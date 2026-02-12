import SwiftUI

public struct RowFormatter: ViewModifier {
  let index: Int
  public init(_ index: Int) {
    self.index = index
  }
  public func body(content: Content) -> some View {
    content
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, DesignTokens.Padding.rowVertical)
      .foregroundStyle(.foreground)
      .cornerRadius(DesignTokens.CornerRadius.small)
      .background(
        index % 2 == 0
          ? DesignTokens.Color.secondaryGroupedBackground
          : DesignTokens.Color.groupedBackground
      )
  }
}

extension View {
  public func rowFormatter(_ index: Int) -> some View {
    modifier(RowFormatter(index))
  }
}
