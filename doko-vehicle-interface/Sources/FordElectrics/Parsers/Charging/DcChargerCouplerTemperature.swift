import ParsingHelpers
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "624897".utf8
    UInt8ToDouble()
  }
}

func parseDcChargerCouplerTemperature(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simDcCharge) var simDcCharge
  if simIdle { return 50 }
#endif
  var input = input[...].utf8
  let temp = try stpxParser().parse(&input)
  return temp - 40
}
