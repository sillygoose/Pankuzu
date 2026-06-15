import Shared
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "62485E".utf8
    Int16ToDouble()
  }
}

func parseAcChargerInputVoltage(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simAcCharge) var simAcCharge
  if simIdle {
    return simAcCharge ? 240 : 0
  }
#endif
  var input = input[...].utf8
  let voltage = try stpxParser().parse(&input)
  return voltage * 0.01
}
