import ParsingHelpers

private struct speedParser: Parser {
  var body: some Parser<Substring.UTF8View, Double> {
    "62F40D".utf8
    UInt8ToDouble()
  }
}

func parseSpeed(_ input: String) throws -> Double {
  var input = input[...].utf8
  let speed = try speedParser().parse(&input)
  return speed
}
