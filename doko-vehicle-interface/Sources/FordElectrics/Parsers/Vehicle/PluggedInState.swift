//import ParsingHelpers
//import DokoDebug
//
//private struct pluggedIn: Parser {
//  func parse(_ input: inout Substring.UTF8View) throws -> Bool {
//    let prefix = input.prefix(8)
//    guard
//      prefix.count == 8,
//      let dword = UInt32(String(decoding: prefix, as: UTF8.self), radix: 16)
//    else { throw ParsingError() }
//    input.removeFirst(8)
//    return ((dword & 0x00004000) != 0)
//  }
//}
//
//private struct stpxParser: Parser {
//  var body: some Parser<Substring.UTF8View, Bool> {
//    "624843".utf8
//    pluggedIn()
//  }
//}
//
//func parsePluggedInState(_ input: String) throws -> Bool {
//#if DEBUG
//  @Shared(.simIdle) var simIdle
//  @Shared(.simAcCharge) var simAcCharge
//  @Shared(.simDcCharge) var simDcCharge
//  if simIdle { return simAcCharge || simDcCharge }
//#endif
//  var input = input[...].utf8
//  return try stpxParser().parse(&input)
//}
