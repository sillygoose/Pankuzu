import VehicleCommon
import DokoSharing

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "624848".utf8
    UInt16ToDouble()
  }
}

public func parseHvbEnergyToEmpty(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle { return 75.0 }
#endif
  var input = input[...].utf8
  let ete = try stpxParser().parse(&input)
  return ete * 2.0 * 0.001
}
