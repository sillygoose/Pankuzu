import Parsing

private struct atfcsd: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      Parse {
        "ATFCSD".utf8
        Prefix(1...) { (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) }
      }.map { _ in () }
      "".utf8
    }
    "OK".utf8
  }
}

public func parseATFCSD(_ input: String) throws -> Void {
  try atfcsd().parse(input)
}
