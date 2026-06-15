import Shared
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "6248F9".utf8
    Int16ToDouble()
  }
}

func parseHvbCurrent(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simTrip) var simTrip
  @Shared(.simAcCharge) var simAcCharge
  @Shared(.simDcCharge) var simDcCharge
  if simIdle {
    if simTrip { return -80 }
    if simAcCharge { return 28 }
    if simDcCharge { return 300 }
    return -4
  }
#endif
  var input = input[...].utf8
  let current = try stpxParser().parse(&input)
  return current * -0.1
}
