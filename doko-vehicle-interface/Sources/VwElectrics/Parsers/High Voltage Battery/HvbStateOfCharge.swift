import VehicleCommon
import DokoSharing

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "62028C".utf8
    UInt8ToDouble()
  }
}

func parseHvbStateOfCharge(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle {
    return 72
  }
#endif
  var input = input[...].utf8
  let soc = try stpxParser().parse(&input)
  return ((soc / 2.5) * 10).rounded() / 10
}
