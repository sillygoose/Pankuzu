import ParsingHelpers

private struct atcaf: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      "ATCAF0".utf8;
      "ATCAF1".utf8;
      "".utf8
    }
    "OK".utf8
  }
}

func parseATCAF(_ input: String) throws {
  var input = input[...].utf8
  try atcaf().parse(&input)
}
