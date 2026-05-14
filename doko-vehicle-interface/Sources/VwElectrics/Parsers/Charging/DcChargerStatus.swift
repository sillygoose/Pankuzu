import Shared
import DokoDebug

/*
 Ready  Technical  Car operation mode  logic  UDS SID
 0x17fc007b 03 22 74 48 55 55 55 55  17
 17fc007b  03 22 74 48 55 55 55 55
 0x17fe007b 04 62 74 48 XX aa aa aa
 17fe007b  04 62 74 48 XX aa aa aa  XX = 0 => standby, XX = 1 => driving, XX = 4 => AC charging, XX = 6 => DC charging
 */

private struct chargerStatus: Parser {
  func parse(_ input: inout Substring.UTF8View) throws -> Bool {
    let prefix = input.prefix(2)
    guard
      prefix.count == 2,
      let uint8 = UInt8(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    input.removeFirst(2)
    return uint8 == 6
  }
}

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Bool> {
    "627448".utf8
    chargerStatus()
  }
}

func parseDcChargerStatus(_ input: String) throws -> Bool {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simDcCharge) var simDcCharge
  if simIdle { return simDcCharge }
#endif
  var input = input[...].utf8
  let status = try stpxParser().parse(&input)
  return status
}
