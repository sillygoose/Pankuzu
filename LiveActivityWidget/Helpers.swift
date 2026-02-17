import SwiftUI

import LiveActivityCore

struct MeasurementValueView<U: Dimension>: View {
  let measurement: Measurement<U>
  let color: Color
  var fractionDigits: Int = 0
  var spacing: CGFloat = 2

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: spacing) {
      Text(
        measurement.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(1))))
      )
      Text(measurement.unit.symbol)
        .font(DesignTokens.Font.body)
    }
    .foregroundStyle(color)
  }
}
