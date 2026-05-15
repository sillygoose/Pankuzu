import Shared
import DokoDebug

private struct chargerStatus: Parser {
  func parse(_ input: inout Substring.UTF8View) throws -> Bool {
    let prefix = input.prefix(2)
    guard
      prefix.count == 2,
      let uint8 = UInt8(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    input.removeFirst(2)
    return uint8 == 4
  }
}

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Bool> {
    "627448".utf8
    chargerStatus()
  }
}

func parseAcChargerStatus(_ input: String) throws -> Bool {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simAcCharge) var simAcCharge
  if simIdle { return simAcCharge }
#endif
  var input = input[...].utf8
  let status = try stpxParser().parse(&input)
  return status
}
