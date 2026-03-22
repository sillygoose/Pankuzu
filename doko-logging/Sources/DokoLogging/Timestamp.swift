import Foundation

import Dependencies

fileprivate let timestampFormat = Date.VerbatimFormatStyle(
  format: "\(minute: .twoDigits):\(second: .twoDigits).\(secondFraction: .fractional(3))",
  timeZone: TimeZone.current,
  calendar: .current
)

public func timestamp(_ date: Date? = nil) -> String {
  @Dependency(\.date.now) var now
  if let date = date { return timestampFormat.format(date) }
  return timestampFormat.format(now)
}
