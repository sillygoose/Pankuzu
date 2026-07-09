import VehicleCommon
import DokoSharing

private enum GearSelected: Int {
  case unknown = -1
  case park = 70
  case reverse = 60
  case neutral = 50
  case drive = 40
  case low = 20

  init(_ rawValue: Int) {
    self = GearSelected(rawValue: rawValue) ?? .unknown
  }
}

private struct gearSelected: Parser {
  func parse(_ input: inout Substring.UTF8View) throws -> Bool {
    let prefix = input.prefix(2)
    guard
      prefix.count == 2,
      let byte = UInt8(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    input.removeFirst(2)
    let gearSelected = GearSelected(rawValue: Int(byte)) ?? .park
    return gearSelected != .park
  }
}

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Bool> {
    "621E12".utf8
    gearSelected()
  }
}

public func parseGearSelected(_ input: String) throws -> Bool {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simTrip) var simTrip
  if simIdle { return simTrip }
#endif
  var input = input[...].utf8
  let gearPosition = try stpxParser().parse(&input)
  return gearPosition
}
