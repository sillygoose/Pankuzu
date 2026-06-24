import Parsing

private struct stcsegr: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      Parse {
        "STCSEGR".utf8
        First().filter { $0 == UInt8(ascii: "0") || $0 == UInt8(ascii: "1") }
      }.map { _ in () }
      "".utf8
    }
    "OK".utf8
  }
}

public func parseSTCSEGR(_ input: String) throws {
  try stcsegr().parse(input)
}
