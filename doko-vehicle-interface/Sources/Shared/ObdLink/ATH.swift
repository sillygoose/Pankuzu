import Parsing

private struct athParser: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      "ATH0".utf8;
      "ATH1".utf8;
      "".utf8;
    }
    "OK".utf8
  }
}

public func parseATH(_ input: String) throws {
  try athParser().parse(input)
}
