import Shared
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "62484A".utf8
    UInt16ToDouble()
  }
}

func parseChargerOutputVoltage(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simAcCharge) var simAcCharge
  @Shared(.simDcCharge) var simDcCharge
  if simIdle {
    if simAcCharge { return 370 }
    if simDcCharge { return 370 }
    return 0
  }
#endif
  var input = input[...].utf8
  let voltage = try stpxParser().parse(&input)
  return voltage * 0.01
}
