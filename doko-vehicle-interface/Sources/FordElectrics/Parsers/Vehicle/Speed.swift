import ParsingHelpers
import DokoDebug

private struct speedParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "621505".utf8
    UInt16ToDouble()
  }
}

func parseSpeed(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simTrip) var simTrip
  if simTrip { return 100.0 }
  if simIdle { return 0.0 }
#endif
  var input = input[...].utf8
  let speed = try speedParser().parse(&input)
  return speed / 128
}
