import VehicleCommon
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "62485F".utf8
    UInt8ToDouble()
  }
}

public func parseAcChargerInputCurrent(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simAcCharge) var simAcCharge
  if simIdle {
    return simAcCharge ? 48 : 0
  }
#endif
  var input = input[...].utf8
  let current = try stpxParser().parse(&input)
  return current
}
