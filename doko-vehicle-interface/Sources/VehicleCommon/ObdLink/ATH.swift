import Parsing

private struct athParser: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      Parse {
        "ATH".utf8
        First().filter { $0 == UInt8(ascii: "0") || $0 == UInt8(ascii: "1") }
      }.map { _ in () }
      "".utf8
    }
    "OK".utf8
  }
}

public func parseATH(_ input: String) throws {
  try athParser().parse(input)
}
