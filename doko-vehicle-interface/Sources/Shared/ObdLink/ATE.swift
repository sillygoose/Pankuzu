//import Shared

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
  var input = input[...].utf8
  try ate().parse(&input)
}
