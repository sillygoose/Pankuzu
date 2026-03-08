import ParsingHelpers
import DokoDebug

private enum DcChargerStatus: Int {
  case unknown = 255
  case notReady = 0
  case initializing = 1
  case ready = 2
  case wchk = 3
  case preC = 4
  case charging = 5
  case done = 6
  case wait = 8
  case ncap = 9
  case fault = 10
  case cchk = 11
}

private struct chargerStatus: Parser {
  func parse(_ input: inout Substring.UTF8View) throws -> Bool {
    let prefix = input.prefix(2)
    guard
      prefix.count == 2,
      let byte = UInt8(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    input.removeFirst(2)
    let chargerStatus = DcChargerStatus(rawValue: Int(byte)) ?? .unknown
    return chargerStatus == .charging
  }
}

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Bool> {
    "62489E".utf8
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
