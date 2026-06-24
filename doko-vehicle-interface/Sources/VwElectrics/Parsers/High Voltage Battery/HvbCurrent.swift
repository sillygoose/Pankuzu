import VehicleCommon
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, (Double, Double)> {
    "621E3D".utf8
    Int32ToDouble()
    UInt8ToDouble()
  }
}

func parseHvbCurrent(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simTrip) var simTrip
  @Shared(.simAcCharge) var simAcCharge
  @Shared(.simDcCharge) var simDcCharge
  if simIdle {
    if simTrip { return -80 }
    if simAcCharge { return 28 }
    if simDcCharge { return 400 }
    return -4
  }
#endif
  var input = input[...].utf8
  let (current, _) = try stpxParser().parse(&input)
  return (current - 150000) * 0.01
}
