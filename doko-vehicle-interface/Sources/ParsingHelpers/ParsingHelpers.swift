import Parsing

public func getStringFromCharacters(_ input: inout Substring.UTF8View, count: Int = 1) throws -> String {
  var string: String = ""
  for _ in 0..<count {
    let prefix = input.prefix(2)
    guard
      prefix.count == 2,
      let byte = UInt8(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    string += String(decoding: [byte], as: UTF8.self)
    input.removeFirst(2)
  }
  return string
}

public struct UInt8ToDouble: Parser {
  public init() {}
  public func parse(_ input: inout Substring.UTF8View) throws -> Double {
    let prefix = input.prefix(2)
    guard
      prefix.count == 2,
      let uint8 = UInt8(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    input.removeFirst(2)
    return Double(uint8)
  }
}

public struct Int16ToDouble: Parser {
  public init() {}
  public func parse(_ input: inout Substring.UTF8View) throws -> Double {
    let prefix = input.prefix(4)
    guard
      prefix.count == 4,
      let uint16 = UInt16(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    input.removeFirst(4)
    let int16 = uint16 > 32767 ? Int16(Int(uint16) - 65536) : Int16(uint16)
    return Double(int16)
  }
}

public struct UInt16ToDouble: Parser {
  public init() {}
  public func parse(_ input: inout Substring.UTF8View) throws -> Double {
    let prefix = input.prefix(4)
    guard
      prefix.count == 4,
      let uint16 = UInt16(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    input.removeFirst(4)
    return Double(uint16)
  }
}

public struct HexTripleToDouble: Parser {
  public init() {}
  public func parse(_ input: inout Substring.UTF8View) throws -> Double {
    let prefix = input.prefix(6)
    guard
      prefix.count == 6,
      let triple = UInt32(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    input.removeFirst(6)
    return Double(triple)
  }
}

public struct UInt32ToDouble: Parser {
  public init() {}
  public func parse(_ input: inout Substring.UTF8View) throws -> Double {
    let prefix = input.prefix(8)
    guard prefix.count == 8,
          let uint32 = UInt32(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    input.removeFirst(8)
    return Double(uint32)
  }
}

public struct Int32ToDouble: Parser {
  public init() {}
  public func parse(_ input: inout Substring.UTF8View) throws -> Double {
    let prefix = input.prefix(8)
    guard
      prefix.count == 8,
      let uint32 = UInt32(String(decoding: prefix, as: UTF8.self), radix: 16)
    else { throw ParsingError() }
    input.removeFirst(8)
    let int16 = uint32 > 2147483647 ? Int32(Int(uint32) - 65536) : Int32(uint32)
    return Double(int16)
  }
}

