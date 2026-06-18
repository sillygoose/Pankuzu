import Shared
import DokoDebug

#if DEBUG
nonisolated(unsafe) private var debugOdometer: Double = 10000
#endif

private struct odometerParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "41A6".utf8
    UInt32ToDouble()
  }
}

func parseOdometer(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle {
    debugOdometer += 0.1
    return debugOdometer
  }
#endif
  var input = input[...].utf8
  let odometer = try odometerParser().parse(&input)
  return odometer * 0.1
}
