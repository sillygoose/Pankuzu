import Parsing

private struct ate: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      "ATE0".utf8;
      "ATE1".utf8;
      "".utf8;
    }
    "OK".utf8
  }
}

public func parseATE(_ input: String) throws {
  try ate().parse(input)
}
