import Parsing

private struct ats: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      "ATS0".utf8;
      "ATS1".utf8;
      "".utf8
    }
    "OK".utf8
  }
}

public func parseATS(_ input: String) throws {
  try ats().parse(input)
}
