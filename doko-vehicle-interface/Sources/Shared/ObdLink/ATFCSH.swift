import Parsing

private struct atfcsh: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      Parse {
        "ATFCSH".utf8
        Prefix(1...) {
          (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) || (UInt8(ascii: "A")...UInt8(ascii: "F")).contains($0)
        }
      }.map { _ in () }
      "".utf8
    }
    "OK".utf8
  }
}

public func parseATFCSH(_ input: String) throws -> Void {
  try atfcsh().parse(input)
}
