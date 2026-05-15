import Parsing

private struct atsp: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      "ATSP".utf8;
      "".utf8
    }
    "OK".utf8
  }
}

public func parseATSP(_ input: String) throws {
  try atsp().parse(input)
}
