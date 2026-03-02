import SwiftUI

import DokoLiveActivityManager

struct MeasurementValueView<U: Dimension>: View {
  let measurement: Measurement<U>
  let color: Color
  var fractionDigits: Int = 0
  var spacing: CGFloat = 2

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: spacing) {
      let formattedMeasurement = String(format: "%.1f", measurement.value)
      Text(formattedMeasurement)
      Text(measurement.unit.symbol)
        .font(DesignTokens.Font.body)
    }
    .foregroundStyle(color)
  }
}
