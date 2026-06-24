import Parsing

private struct atfcsm: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      Parse {
        "ATFCSM".utf8
        First().filter { $0 == UInt8(ascii: "0") || $0 == UInt8(ascii: "1")  || $0 == UInt8(ascii: "2") }
      }.map { _ in () }
      "".utf8
    }
    "OK".utf8
  }
}

public func parseATFCSM(_ input: String) throws {
  try atfcsm().parse(input)
}
