import Parsing

private struct atcaf: Parser {
  var body: some Parser<Substring.UTF8View, Void> {
    OneOf {
      Parse {
        "ATCAF".utf8
        First().filter { $0 == UInt8(ascii: "0") || $0 == UInt8(ascii: "1") }
      }.map { _ in () }
      "".utf8
    }
    "OK".utf8
  }
}

public func parseATCAF(_ input: String) throws -> Void {
  try atcaf().parse(input)
}

/*
 var body: some Parser<Substring.UTF8View, Date> {
   Parse(Date.init(year:month:day:hour:minute:second:nanosecond:timeZone:)) {
     Digits(4)
     "-".utf8
     Digits(2).filter { (1...12).contains($0) }
     "-".utf8
     Digits(2).filter { (1...31).contains($0) }
     "T".utf8
     Digits(2).filter { $0 < 24 }
     ":".utf8
     Digits(2).filter { $0 < 60 }
     ":".utf8
     Digits(2).filter { $0 <= 60 }
     Parse {
       ".".utf8
       Prefix(1...9, while: (UInt8(ascii: "0")...UInt8(ascii: "9")).contains)
         .compactMap { n in Int(Substring(n)).map { $0 * Int(pow(10, 9 - Double(n.count))) } }
     }
     .replaceError(with: 0)
     OneOf {
       "Z".utf8.map { 0 }
       Parse {
         OneOf {
           "+".utf8.map { 1 }
           "-".utf8.map { -1 }
         }
         Digits(2).filter { $0 < 24 }.map { $0 * 60 * 60 }
         ":".utf8
         Digits(2).filter { $0 < 60 }.map { $0 * 60 }
       }
       .map { $0 * ($1 + $2) }
     }
   }

 */
