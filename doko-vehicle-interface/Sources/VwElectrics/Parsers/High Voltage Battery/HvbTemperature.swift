import VehicleCommon
import DokoSharing

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "622A0B".utf8
    UInt8ToDouble()
  }
}

func parseHvbTemperature(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle {
    return 50
  }
#endif
  var input = input[...].utf8
  let temperature = try stpxParser().parse(&input)
  return temperature / 2  - 40
}
