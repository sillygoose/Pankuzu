import Foundation

fileprivate let timestampFormat = Date.VerbatimFormatStyle(
  format: "\(minute: .twoDigits):\(second: .twoDigits).\(secondFraction: .fractional(3))",
  timeZone: TimeZone.current,
  calendar: .current
)

public func timestamp(_ date: Date? = nil) -> String {
  if let date = date { return timestampFormat.format(date) }
  return timestampFormat.format(Date.now)
}
