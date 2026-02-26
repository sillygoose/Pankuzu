import ParsingHelpers
import DokoDebug

/*
 Ready  Battery  HV Battery voltage  V  UDS SID
 0x17fc007b 03 22 1e 3b 55 55 55 55  17
 17fc007b  03 22 1e 3b 55 55 55 55
 0x17fe007b 05 62 1e 3b XX YY aa aa
 17fe007b  05 62 1e 3b XX YY aa aa  (XX*2^8+YY)/4 = Voltage
 */

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "621E3B".utf8
    UInt16ToDouble()
  }
}

func parseHvbVoltage(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle { return 350 }
#endif
  var input = input[...].utf8
  let voltage = try stpxParser().parse(&input)
  return voltage / 4
}
