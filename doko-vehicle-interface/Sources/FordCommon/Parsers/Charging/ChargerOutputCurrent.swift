import VehicleCommon
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "624850".utf8
    Int16ToDouble()
  }
}

public func parseChargerOutputCurrent(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simAcCharge) var simAcCharge
  @Shared(.simDcCharge) var simDcCharge
  if simIdle {
    if simAcCharge { return 26 }
    if simDcCharge { return 200 }
    return 0
  }
#endif
  var input = input[...].utf8
  let current = try stpxParser().parse(&input)
  return current * 0.01
}
