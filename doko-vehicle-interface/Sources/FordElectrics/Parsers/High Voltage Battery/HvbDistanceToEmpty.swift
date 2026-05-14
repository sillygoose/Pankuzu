import Shared
import DokoDebug

/*
 DID 2AB4 — Range Reserve:
 Bytes [2:4]: u16 km → 345 km

 DID 2AB6 — Range Displayed:
 Bytes [0:2]: u16 miles → 215 miles

   .batteryCurrent2(ERROR) [STPX h:710, d:222AB5 → 77A622AB501160000011600000000]
   .batteryCurrent3(ERROR) [222AB5 → 77A622AB501160000011600000000]

 77A 62 2AB5 0116 0000 0116 0000 0000
     62 2AB6 0131 0131 000006
 278 km
 */

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "622AB5".utf8
    UInt16ToDouble()
  }
}

func parseHvbDistanceToEmpty(_ input: String) throws -> Double {
  return 172.0
}
