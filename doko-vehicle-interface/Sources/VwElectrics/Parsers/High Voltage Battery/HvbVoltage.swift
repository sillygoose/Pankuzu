import VehicleCommon
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "621E3B".utf8
    UInt16ToDouble()
  }
}

func parseHvbVoltage(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle { return 350 }
#endif
  var input = input[...].utf8
  let voltage = try stpxParser().parse(&input)
  return voltage / 4
}
