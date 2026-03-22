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

  public var jsonString: String? {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(self) else { return nil }
    return String(data: data, encoding: .utf8)
  }
}
