import ParsingHelpers
import DokoDebug

private struct anyVinParser: Parser {
  func parse(_ input: inout Substring.UTF8View) throws -> String {
    let vin = try getStringFromCharacters(&input, count: 17)
    return vin
  }
}

private struct vinParser: Parser {
  var body: some Parser<Substring.UTF8View, String> {
    "490201".utf8
    anyVinParser()
  }
}

func parseVin(_ input: String) throws -> String {
#if DEBUG
  @Shared(.simIdle) var simIdle
//    if simIdle { return "1FTVW3L76RWG00000" } //### debugging control?
  if simIdle { return "1V2DNPE81PC030349" }
#endif
  var input = input[...].utf8
  return try vinParser().parse(&input)
}
