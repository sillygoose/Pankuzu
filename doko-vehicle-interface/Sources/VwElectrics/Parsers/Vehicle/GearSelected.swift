import ParsingHelpers
import DokoDebug

/*
 Ready  Technical  Driving mode position (P-N-D-B)  logic
 UDS SID  0x17fc0076 03 22 21 0e 55 55 55 55
 17  17fc0076  03 22 21 0e 55 55 55 55
 0x17fe0076 05 62 21 0e XX YY aa aa
 17fe0076  05 62 21 0e XX YY aa aa  YY=08->P,YY=05->D,YY=0c->B,YY=07->R,YY=06->N
 */

private enum GearSelected: Int {
  case unknown = -1
  case park = 8
  case reverse = 7
  case neutral = 6
  case drive = 5
  case regen = 12

  init(_ rawValue: Int) {
    self = GearSelected(rawValue: rawValue) ?? .unknown
  }
}

private struct gearSelected: Parser {
  func parse(_ input: inout Substring.UTF8View) throws -> Bool {
    input.removeFirst(2)
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
    "62210E".utf8
    gearSelected()
  }
}

func parseGearSelected(_ input: String) throws -> Bool {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simTrip) var simTrip
  if simIdle { return simTrip }
#endif
  var input = input[...].utf8
  let gearPosition = try stpxParser().parse(&input)
  return gearPosition
}
