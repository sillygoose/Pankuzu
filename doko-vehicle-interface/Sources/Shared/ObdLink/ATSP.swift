//import Shared

private struct actualATSP: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      "ATSP0".utf8;
      "".utf8
    }
    "OK".utf8
  }
}

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
  var input = input[...].utf8
  try atsp().parse(&input)
}
