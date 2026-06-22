import Shared
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "624844".utf8
    UInt8ToDouble()
  }
}

func parseHvbChargeVoltageRequested(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle { return 350 }
#endif
  var input = input[...].utf8
  let voltage = try stpxParser().parse(&input)
  return voltage * 2
}
