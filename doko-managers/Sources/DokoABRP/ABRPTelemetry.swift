import Foundation

public struct ABRPTelemetry: Encodable, Sendable {
  public var utc: Int
  public var soc: Double?
  public var soh: Double?
  public var speed: Double?
  public var lat: Double?
  public var lon: Double?
  public var elevation: Double?
  public var heading: Double?
  public var isCharging: Int?
  public var isDCFC: Int?
  public var isParked: Int?
  public var power: Double?
  public var battTemp: Double?
  public var extTemp: Double?
  public var odometer: Double?
  public var sessionId: String?

  enum CodingKeys: String, CodingKey {
    case utc
    case soc, soh
    case speed, lat, lon, elevation, heading
    case isCharging = "is_charging"
    case isDCFC = "is_dcfc"
    case isParked = "is_parked"
    case power
    case battTemp = "batt_temp"
    case extTemp = "ext_temp"
    case odometer
    case sessionId = "session_id"
  }

  public init(utc: Int) {
    self.utc = utc
  }

  public var description: String {
    var parts: [String] = []
    if let soc { parts.append(String(format: "soc=%.0f%%", soc)) }
    if let power { parts.append(String(format: "pwr=%.1fkW", power)) }
    if let speed { parts.append(String(format: "spd=%.0f", speed)) }
    if let battTemp { parts.append(String(format: "batt=%.0f°", battTemp)) }
    if let extTemp { parts.append(String(format: "ext=%.0f°", extTemp)) }
    if let odometer { parts.append(String(format: "odo=%.0f", odometer)) }
    if let isCharging { parts.append("charging=\(isCharging)") }
    if let isDCFC, isDCFC == 1 { parts.append("dcfc=1") }
    return parts.joined(separator: " ")
  }

  public var jsonString: String? {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(self) else { return nil }
    return String(data: data, encoding: .utf8)
  }
}
