import SwiftUI

import DokoLiveActivityManager

struct DokoWidgetIcon: View {
  var height: CGFloat = 32

  var body: some View {
    Image("WidgetIcon")
      .resizable()
      .scaledToFit()
      .frame(height: height)
      .clipShape(RoundedRectangle(cornerRadius: height * 0.2))
  }
}
