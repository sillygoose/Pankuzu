import ParsingHelpers
import DokoDebug

/*
 82K096S3PLG0
 */

private struct anyBatteryPackParser: Parser {
  func parse(_ input: inout Substring.UTF8View) throws -> String {
    let batteryPack = try getStringFromCharacters(&input, count: 12)
    return batteryPack
  }
}

private struct batteryPackParser: Parser {
  var body: some Parser<Substring.UTF8View, String> {
    "62F1B3".utf8
    anyBatteryPackParser()
  }
}

func parseHvbOriginalCapacity(_ input: String) throws -> Double {
#if DEBUG
  @Shared(.simIdle) var simIdle
  if simIdle {
    return 79.9
  }
#endif
  var input = input[...].utf8
  let batteryPack = try batteryPackParser().parse(&input)
  let id4BatteryPacks: [String: Double] = [
    "82K096S3PLG0": 77.0,
    "82K096S3PSK0": 79.9,
  ]
  guard let originalCapacity = id4BatteryPacks[batteryPack] else { throw ParsingError() }
  return originalCapacity
}
