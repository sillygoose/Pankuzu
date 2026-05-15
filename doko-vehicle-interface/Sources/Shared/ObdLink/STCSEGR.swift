import Parsing

private struct stcsegr: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      "STCSEGR0".utf8;
      "STCSEGR1".utf8;
      "".utf8
    }
    "OK".utf8
  }
}

public func parseSTCSEGR(_ input: String) throws {
  try stcsegr().parse(input)
}
