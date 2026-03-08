import ParsingHelpers
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "624888".utf8
    UInt8ToDouble()
  }
}

func parseAcChargerCouplerTemperature(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simAcCharge) var simAcCharge
  if simIdle { return 50 }
#endif
  var input = input[...].utf8
  let temp = try stpxParser().parse(&input)
  return temp - 40
}
