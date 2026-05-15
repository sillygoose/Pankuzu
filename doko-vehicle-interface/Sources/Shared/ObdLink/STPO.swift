import Parsing

private struct stpo: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      "STPO".utf8
      "".utf8
    }
    "OK".utf8
  }
}

public func parseSTPO(_ input: String) throws -> Void {
  try stpo().parse(input)
}
