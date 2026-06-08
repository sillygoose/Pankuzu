import Shared
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "624850".utf8
    Int16ToDouble()
  }
}

func parseChargerOutputCurrent(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simAcCharge) var simAcCharge
  if simIdle {
    if simAcCharge { return 28 }
    return 0
  }
#endif
  var input = input[...].utf8
  let current = try stpxParser().parse(&input)
  return current * 0.01
}
