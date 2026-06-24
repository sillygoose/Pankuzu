import VehicleCommon
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "624845".utf8
    UInt8ToDouble()
  }
}

public func parseHvbStateOfCharge(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle { return 72 }
#endif
  var input = input[...].utf8
  let soc = try stpxParser().parse(&input)
  return soc * 0.5
}
