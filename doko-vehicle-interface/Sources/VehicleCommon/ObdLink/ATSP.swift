import Parsing

private struct atsp: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      Parse {
        "ATSP".utf8
        Prefix(1...) { (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) }
      }.map { _ in () }
      "".utf8
    }
    "OK".utf8
  }
}

public func parseATSP(_ input: String) throws -> Void {
  try atsp().parse(input)
}
