import Parsing

private struct atz: Parser {
  var body: some Parser<Substring.UTF8View, Substring> {
    Parse(Substring.init) {
      OneOf {
        "ATZ".utf8;
        "".utf8
      }
      Rest().map(Substring.init)
    }
  }
}

public func parseATZ(_ input: String) throws -> String {
  let version = try atz().parse(input)
  return String(version)
}
