import Parsing

private struct ats: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      Parse {
        "ATS".utf8
        First().filter { $0 == UInt8(ascii: "0") || $0 == UInt8(ascii: "1") }
      }.map { _ in () }
      "".utf8
    }
    "OK".utf8
  }
}

public func parseATS(_ input: String) throws {
  try ats().parse(input)
}
