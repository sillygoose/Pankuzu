import Parsing

private struct ate: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      Parse {
        "ATE".utf8
        First().filter { $0 == UInt8(ascii: "0") || $0 == UInt8(ascii: "1") }
      }.map { _ in () }
      "".utf8
    }
    "OK".utf8
  }
}

public func parseATE(_ input: String) throws {
  try ate().parse(input)
}
