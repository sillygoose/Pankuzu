import ParsingHelpers
import DokoDebug

/*
 Ready  Battery  HV Battery temp (main value)  °C  UDS SID
 0x17fc007b 03 22 2a 0b 55 55 55 55  17
 17fc007b  03 22 2a 0b 55 55 55 55
 0x17fe007b 03 62 2a 0b XX aa aa aa
 17fe007b  03 62 2a 0b XX aa aa aa  XX/2-40=temperature in C
 */

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "622A0B".utf8
    UInt8ToDouble()
  }
}

func parseHvbTemperature(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle {
    return 50
  }
#endif
  var input = input[...].utf8
  let temperature = try stpxParser().parse(&input)
  return temperature / 2  - 40
}
