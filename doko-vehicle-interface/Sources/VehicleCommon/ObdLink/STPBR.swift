import Parsing

private struct stpbr: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      Parse {
        "STPBR".utf8
        Prefix(1...) { (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) }
      }.map { _ in () }
      "".utf8
    }
    "OK".utf8
  }
}

public func parseSTPBR(_ input: String) throws -> Void {
  try stpbr().parse(input)
}
