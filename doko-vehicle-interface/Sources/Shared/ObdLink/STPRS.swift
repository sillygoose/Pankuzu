import Parsing

private struct stprs: Parser {
  var body: some Parser<Substring.UTF8View, Substring> {
    Parse(Substring.init) {
      OneOf {
        "STPRS".utf8;
        "".utf8
      }
      Rest().map(Substring.init)
    }
  }
}

public func parseSTPRS(_ input: String) throws -> String {
  let canbusProtocol = try stprs().parse(input)
  return String(canbusProtocol)
}
