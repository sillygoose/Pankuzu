import VehicleCommon
import DokoSharing

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "62480D".utf8
    UInt16ToDouble()
  }
}

public func parseHvbVoltage(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle { return 350 }
#endif
  var input = input[...].utf8
  let voltage = try stpxParser().parse(&input)
  return voltage * 0.01
}
