import Testing
import Foundation
import DokoABRP

@Suite("ABRPTelemetry")
struct ABRPTelemetryTests {

  // MARK: - JSON validity

  @Test func producesValidJSON() throws {
    var telemetry = ABRPTelemetry(utc: 1_700_000_000)
    telemetry.soc = 75.0
    let jsonString = try #require(telemetry.jsonString)
    let data = try #require(jsonString.data(using: .utf8))
    let object = try #require(try? JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(object["utc"] as? Int == 1_700_000_000)
    #expect(object["soc"] as? Double == 75.0)
  }

  // MARK: - utc

  @Test func utcAlwaysPresent() throws {
    let telemetry = ABRPTelemetry(utc: 1_700_000_000)
    let json = try #require(telemetry.jsonString)
    #expect(json.contains("\"utc\":1700000000"))
  }

  // MARK: - Nil fields omitted

  @Test func nilFieldsOmitted() throws {
    let telemetry = ABRPTelemetry(utc: 1_700_000_000)
    let json = try #require(telemetry.jsonString)
    #expect(!json.contains("soc"))
    #expect(!json.contains("soh"))
    #expect(!json.contains("speed"))
    #expect(!json.contains("lat"))
    #expect(!json.contains("lon"))
    #expect(!json.contains("is_charging"))
    #expect(!json.contains("power"))
    #expect(!json.contains("batt_temp"))
    #expect(!json.contains("ext_temp"))
    #expect(!json.contains("odometer"))
  }

  // MARK: - Snake_case CodingKeys

  @Test func snakeCaseKeys() throws {
    var telemetry = ABRPTelemetry(utc: 1_700_000_000)
    telemetry.isCharging = 1
    telemetry.isDCFC = 0
    telemetry.isParked = 1
    telemetry.battTemp = 25.0
    telemetry.extTemp = 18.5
    telemetry.sessionId = "abc123"
    let json = try #require(telemetry.jsonString)
    #expect(json.contains("\"is_charging\""))
    #expect(json.contains("\"is_dcfc\""))
    #expect(json.contains("\"is_parked\""))
    #expect(json.contains("\"batt_temp\""))
    #expect(json.contains("\"ext_temp\""))
    #expect(json.contains("\"session_id\""))
    // Swift property names must not appear
    #expect(!json.contains("\"isCharging\""))
    #expect(!json.contains("\"isDCFC\""))
    #expect(!json.contains("\"isParked\""))
    #expect(!json.contains("\"battTemp\""))
    #expect(!json.contains("\"extTemp\""))
    #expect(!json.contains("\"sessionId\""))
  }

  @Test func camelCaseKeysUnchanged() throws {
    var telemetry = ABRPTelemetry(utc: 1_700_000_000)
    telemetry.soc = 80.0
    telemetry.soh = 98.0
    telemetry.speed = 60.0
    telemetry.lat = 37.3861
    telemetry.lon = -122.0839
    telemetry.elevation = 100.0
    telemetry.heading = 270.0
    telemetry.power = -15.2
    telemetry.odometer = 12345.6
    let json = try #require(telemetry.jsonString)
    #expect(json.contains("\"soc\""))
    #expect(json.contains("\"soh\""))
    #expect(json.contains("\"speed\""))
    #expect(json.contains("\"lat\""))
    #expect(json.contains("\"lon\""))
    #expect(json.contains("\"elevation\""))
    #expect(json.contains("\"heading\""))
    #expect(json.contains("\"power\""))
    #expect(json.contains("\"odometer\""))
  }

  // MARK: - Charge/trip flags

  @Test func tripFlags() {
    var telemetry = ABRPTelemetry(utc: 1_700_000_000)
    telemetry.isCharging = 0
    telemetry.isDCFC = 0
    telemetry.isParked = 0
    #expect(telemetry.isCharging == 0)
    #expect(telemetry.isDCFC == 0)
    #expect(telemetry.isParked == 0)
  }

  @Test func acChargeFlags() {
    var telemetry = ABRPTelemetry(utc: 1_700_000_000)
    telemetry.isCharging = 1
    telemetry.isDCFC = 0
    telemetry.isParked = 1
    #expect(telemetry.isCharging == 1)
    #expect(telemetry.isDCFC == 0)
    #expect(telemetry.isParked == 1)
  }

  @Test func dcChargeFlags() {
    var telemetry = ABRPTelemetry(utc: 1_700_000_000)
    telemetry.isCharging = 1
    telemetry.isDCFC = 1
    telemetry.isParked = 1
    #expect(telemetry.isCharging == 1)
    #expect(telemetry.isDCFC == 1)
    #expect(telemetry.isParked == 1)
  }
}
