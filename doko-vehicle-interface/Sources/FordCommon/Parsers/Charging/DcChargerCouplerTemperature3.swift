import VehicleCommon
import DokoSharing

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "6248A4".utf8
    UInt8ToDouble()
  }
}

public func parseDcChargerCouplerTemperature3(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simDcCharge) var simDcCharge
  if simIdle { return 60 }
#endif
  var input = input[...].utf8
  let temp = try stpxParser().parse(&input)
  return temp - 40
}
