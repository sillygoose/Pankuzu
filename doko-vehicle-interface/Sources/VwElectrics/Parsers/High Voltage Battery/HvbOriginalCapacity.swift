import VehicleCommon
import DokoDebug
import DokoLogging

private struct anyBatteryPackParser: Parser {
  func parse(_ input: inout Substring.UTF8View) throws -> String {
    let batteryPack = try getStringFromCharacters(&input, count: 12)
    return batteryPack
  }
}

private struct batteryPackParser: Parser {
  var body: some Parser<Substring.UTF8View, String> {
    "62F1B3".utf8
    "04".utf8
    "7100".utf8
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
    "82K0963SK011": 79.9,
  ]
  guard let originalCapacity = id4BatteryPacks[batteryPack] else {
    DokoLogging.shared.postLoggingResponse(.error(".hvbOriginalCapacity: \(batteryPack)"))
    throw ParsingError()
  }
  return originalCapacity
}
