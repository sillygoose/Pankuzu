import SwiftUI

public struct GridStatusButton: View {
  let leftSymbolTitle: String
  let leftSymbol: String
  let leftSymbolColor: Color
  let centerSymbol: String?
  let centerSymbolColor: Color?
  let centerSymbolTitle: String
  let rightSymbol: String?
  let rightSymbolColor: Color?
  let rightSymbolTitle: String
  let action: () -> Void
  
  public init(
    leftSymbol: String, leftSymbolColor: Color, leftSymbolTitle: String,
    centerSymbol: String? = nil, centerSymbolColor: Color? = nil, centerSymbolTitle: String,
    rightSymbol: String? = nil, rightSymbolColor: Color? = nil, rightSymbolTitle: String,
    action: @escaping () -> Void
  ) {
    self.leftSymbol = leftSymbol
    self.leftSymbolColor = leftSymbolColor
    self.leftSymbolTitle = leftSymbolTitle
    self.centerSymbol = centerSymbol
    self.centerSymbolColor = centerSymbolColor
    self.centerSymbolTitle = centerSymbolTitle
    self.rightSymbol = rightSymbol
    self.rightSymbolColor = rightSymbolColor
    self.rightSymbolTitle = rightSymbolTitle
    self.action = action
  }
  
  public var body: some View {
    Button(action: action) {
      VStack {
        Text("Scan Tool Status")
          .lineLimit(1)
          .font(DesignTokens.Font.headline)
          .foregroundStyle(.gray)
        HStack(spacing: 0) {
          VStack {
            Image(systemName: leftSymbol)
              .font(DesignTokens.Font.largeTitle)
              .bold()
              .foregroundStyle(leftSymbolColor)
            Text(leftSymbolTitle)
              .lineLimit(1)
              .font(DesignTokens.Font.headline)
              .foregroundStyle(.gray)
          }
          .frame(maxWidth: .infinity)
          if let centerSymbol, let centerSymbolColor {
            VStack {
              Image(systemName: centerSymbol)
                .font(DesignTokens.Font.largeTitle)
                .bold()
                .foregroundStyle(centerSymbolColor)
              Text(centerSymbolTitle)
                .lineLimit(1)
                .font(DesignTokens.Font.headline)
                .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)
          }
          VStack {
            if let rightSymbol, let rightSymbolColor {
              Image(systemName: rightSymbol)
                .font(DesignTokens.Font.largeTitle)
                .bold()
                .symbolEffect(.pulse, options: .repeating)
                .foregroundStyle(rightSymbolColor)
            } else {
              Image(systemName: "square.fill")
                .font(DesignTokens.Font.largeTitle)
                .opacity(0)
            }
            Text(rightSymbolTitle)
              .lineLimit(1)
              .font(DesignTokens.Font.headline)
              .foregroundStyle(.gray)
          }
          .frame(maxWidth: .infinity)
        }
      }
    }
    .buttonStyle(.borderless)
    .padding(DesignTokens.Padding.cardInsets)
    .background(DesignTokens.Color.cardBackground)
    .cornerRadius(DesignTokens.CornerRadius.medium)
  }
}

#Preview("Status Button") {
  NavigationStack {
    ScrollView {
      Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
        GridStatusButton(
          leftSymbol: "togglepower",
          leftSymbolColor: .green,
          leftSymbolTitle: "Enable",
          centerSymbol: "antenna.radiowaves.left.and.right",
          centerSymbolColor: .blue,
          centerSymbolTitle: "Bluetooth",
          rightSymbol: "car",
          rightSymbolColor: .red,
          rightSymbolTitle: "Activity"
        ) {
          print("Bluetooth button pressed")
        }
        GridStatusButton(
          leftSymbol: "togglepower",
          leftSymbolColor: .green,
          leftSymbolTitle: "Enable",
          centerSymbol: "antenna.radiowaves.left.and.right",
          centerSymbolColor: .blue,
          centerSymbolTitle: "Bluetooth",
          rightSymbol: nil,
          rightSymbolColor: .red,
          rightSymbolTitle: "Activity"
        ) {
          print("Bluetooth button pressed")
        }
      }
    }
    .buttonStyle(.plain)
    .listRowBackground(Color.clear)
    .padding([.leading, .trailing], 10)
    .preferredColorScheme(.dark)
  }
}
