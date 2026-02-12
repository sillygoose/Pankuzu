import ParsingHelpers
import DokoDebug

private struct odometerAvailable: Parser {
  func parse(_ input: inout Substring.UTF8View) throws -> UInt32 {
    let prefix = input.prefix(8)
    guard
      prefix.count == 8,
      let uint32 = UInt32(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    input.removeFirst(8)
    return uint32
  }
}

private struct odometerAvailableParser: Parser {
  var body: some Parser<Substring.UTF8View, UInt32> {
    "41A0".utf8
    odometerAvailable()
  }
}

func parseOdometerAvailable(_ input: String) throws -> Bool {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle { return true }
#endif
  var input = input[...].utf8
  let pids = try odometerAvailableParser().parse(&input)
  return (pids & 0x04000000) != 0
}
