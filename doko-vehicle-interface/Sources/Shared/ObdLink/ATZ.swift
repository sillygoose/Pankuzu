//import Shared

private struct atz: Parser {
  var body: some Parser<Substring.UTF8View, Substring.UTF8View> {
    OneOf {
      "ATZ".utf8;
      "".utf8
    }
    Rest()
  }
}

public func parseATZ(_ input: String) throws -> String {
  var input = input[...].utf8
  let version = try atz().parse(&input)
  return String(bytes: version, encoding: .utf8) ?? "???"
}
