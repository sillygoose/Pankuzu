import ParsingHelpers

private struct speedParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "621505".utf8
    UInt16ToDouble()
  }
}

func parseSpeed(_ input: String) throws -> Double {
  var input = input[...].utf8
  let speed = try speedParser().parse(&input)
  return speed / 128
}
