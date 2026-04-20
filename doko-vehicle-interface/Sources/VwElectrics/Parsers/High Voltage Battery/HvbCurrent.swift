import ParsingHelpers
import DokoDebug

/*
 Ready  Battery  HV Battery current  A  UDS SID
 0x17fc007b 03 22 1e 3d 55 55 55 55  17
 17fc007b  03 22 1e 3d 55 55 55 55
 0x17fe007b 07 62 1e 3d WW XX YY ZZ
 17fe007b  07 62 1e 3d WW XX YY ZZ  (WW*2^32+XX*2^16+YY*2^8+ZZ-150000)/100 = HV current in decimal value
 Negative value is out from battery (consumption) and positive value is into battery (charging or regen)
 */

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "621E3D00".utf8
    Int32ToDouble()
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
  let current = try stpxParser().parse(&input)
  return (current - 150000) * 0.01
}
