import ParsingHelpers

private struct ats: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      "ATS0".utf8;
      "ATS1".utf8;
      "".utf8
    }
    "OK".utf8
  }
}

func parseATS(_ input: String) throws {
  var input = input[...].utf8
  try ats().parse(&input)
}
