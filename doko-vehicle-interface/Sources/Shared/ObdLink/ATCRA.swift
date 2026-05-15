import Parsing

private struct atcra: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      Parse {
        "ATCRA".utf8
        Prefix(1...) {
          (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) ||
          (UInt8(ascii: "A")...UInt8(ascii: "F")).contains($0) ||
          (UInt8(ascii: "X")...UInt8(ascii: "X")).contains($0)
        }
      }.map { _ in () }
      "".utf8
    }
    "OK".utf8
  }
}

public func parseATCRA(_ input: String) throws -> Void {
  try atcra().parse(input)
}
