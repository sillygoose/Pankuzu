import Shared
import DokoDebug

private struct odometerParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "62295A".utf8
    HexTripleToDouble()
  }
}

func parseOdometer(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle { return 10000.0 }
#endif
  var input = input[...].utf8
  let odometer = try odometerParser().parse(&input)
  return odometer
}
