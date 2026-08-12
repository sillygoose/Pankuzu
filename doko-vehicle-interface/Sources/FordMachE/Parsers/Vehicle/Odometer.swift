import VehicleCommon
import DokoSharing

#if DEBUG
nonisolated(unsafe) private var debugOdometer: Double = 10000
#endif

private struct odometerParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "62404C".utf8
    HexTripleToDouble()
  }
}

public func parseOdometer(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle {
    defer { debugOdometer += 0.3 }
    return debugOdometer
  }
#endif
  var input = input[...].utf8
  let rawOdometer = try odometerParser().parse(&input)
  let tenthsOdometer = rawOdometer * 0.1
  return (tenthsOdometer * 10).rounded() / 10
}
