import Shared
import DokoDebug

/*
 Ready  LSD  ODOMETER  km  UDS SID
 0x17fc0076 03 22 29 5a 55 55 55 55  17
 17fc0076  03 22 29 5a 55 55 55 55
 0x17fe0076 06 62 29 5a XX YY ZZ aa
 17fe0076  06 62 29 5a XX YY ZZ aa  (XX*2^16+YY*2^8+ZZ) = km in decimal

 22295A → 62295A 009D4B
 */

private struct odometerParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "62295A".utf8
    HexTripleToDouble()
  }
}

func parseOdometer(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle { return 10000.0 }
#endif
  var input = input[...].utf8
  let odometer = try odometerParser().parse(&input)
  return odometer
}
