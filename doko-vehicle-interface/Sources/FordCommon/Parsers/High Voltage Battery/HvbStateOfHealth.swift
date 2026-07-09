import VehicleCommon
import DokoSharing

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "62490C".utf8
    UInt8ToDouble()
  }
}

public func parseHvbStateOfHealth(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle { return 95 }
#endif
  var input = input[...].utf8
  let soh = try stpxParser().parse(&input)
  return soh * 0.5
}
