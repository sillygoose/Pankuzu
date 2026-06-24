import VehicleCommon
import DokoDebug

private enum AcChargerStatus: Int {
  case unknown = 255
  case notReady = 0
  case ready = 1
  case fault = 2
  case wchk = 3
  case preC = 4
  case charging = 5
  case done = 6
  case extC = 7
  case initializing = 8
}

private struct chargerStatus: Parser {
  func parse(_ input: inout Substring.UTF8View) throws -> Bool {
    let prefix = input.prefix(2)
    guard
      prefix.count == 2,
      let byte = UInt8(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    input.removeFirst(2)
    let chargerStatus = AcChargerStatus(rawValue: Int(byte)) ?? .unknown
    return chargerStatus == .charging
  }
}

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Bool> {
    "62484F".utf8
    chargerStatus()
  }
}

public func parseAcChargerStatus(_ input: String) throws -> Bool {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simAcCharge) var simAcCharge
  if simIdle { return simAcCharge }
#endif
  var input = input[...].utf8
  let status = try stpxParser().parse(&input)
  return status
}
