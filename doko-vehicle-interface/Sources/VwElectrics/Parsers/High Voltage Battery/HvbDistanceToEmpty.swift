import ParsingHelpers
import DokoDebug

/*
 DID 2AB4 — Range Reserve:
 Bytes [2:4]: u16 km → 345 km

 DID 2AB6 — Range Displayed:
 Bytes [0:2]: u16 miles → 215 miles */

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "622AB6".utf8
    UInt16ToDouble()
  }
}

func parseHvbDistanceToEmpty(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle {
    return 172
  }
#endif
  var input = input[...].utf8
  let dte = try stpxParser().parse(&input)
  return dte
}
