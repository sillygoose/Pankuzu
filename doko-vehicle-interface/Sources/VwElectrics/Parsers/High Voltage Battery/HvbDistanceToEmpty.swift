import Shared
import DokoDebug

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "622AB5".utf8
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
