import ParsingHelpers
import DokoDebug

/*
 //Battery SOC %  UDS SID  0x17fc007b 03 22 02 8c 55 55 55 55
 //17                        17fc007b 03 22 02 8c 55 55 55 55
 //                        0x17fe007b 04 62 02 8c XX aa aa aa
 //                          17fe007b 04 62 02 8c XX aa aa aa  XX/2,5= SOC in decimal
 */

private struct stpxParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "62028C".utf8
    UInt8ToDouble()
  }
}

func parseHvbStateOfCharge(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle {
    return 72
  }
#endif
  var input = input[...].utf8
  let soc = try stpxParser().parse(&input)
  return soc / 2.5
}
