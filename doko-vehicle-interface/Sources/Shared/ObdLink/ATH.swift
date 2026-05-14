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
  var input = input[...].utf8
  try athParser().parse(&input)
}
