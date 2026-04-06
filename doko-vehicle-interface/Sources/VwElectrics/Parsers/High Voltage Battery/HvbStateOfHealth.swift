import ParsingHelpers
import DokoDebug

/*
 DID 2AB2 — HV Usable Capacity (→ SOH):
 Response: 62 2A B2 05 91 04 00
 Bytes [0:2]: u16 * 50 / 1000 = kWh
 0x0591 = 1425 → 71.25 kWh
 Nominal for 82 kWh pack ≈ 77 kWh → SOH ≈ 92.5%
 */

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "622AB2".utf8
    UInt16ToDouble()
  }
}

func parseHvbStateOfHealth(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle {
    return 97
  }
#endif
  var input = input[...].utf8
  let soh = try stpxParser().parse(&input)
  return (soh * 0.05) / 77.0 //###
}
