import Foundation

import VehicleCommon
import DokoSharing

#if DEBUG
nonisolated(unsafe) private var debugOdometer: Double = 10000
#endif

private struct odometerParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "62295A".utf8
    HexTripleToDouble()
  }
}

func parseOdometer(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle {
    defer { debugOdometer += 0.3 }
    return floor(debugOdometer)
  }
#endif
  var input = input[...].utf8
  let odometer = try odometerParser().parse(&input)
  return odometer
}
