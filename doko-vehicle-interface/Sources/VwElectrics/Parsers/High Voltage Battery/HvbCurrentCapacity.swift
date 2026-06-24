import VehicleCommon
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "622AB2".utf8
    UInt16ToDouble()
  }
}

func parseHvbCurrentCapacity(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle {
    return 77.0
  }
#endif
  var input = input[...].utf8
  let currentCapacity = try stpxParser().parse(&input)
  return currentCapacity * 0.05
}
