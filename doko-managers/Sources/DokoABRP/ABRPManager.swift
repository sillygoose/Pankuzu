import Foundation
import OSLog

import Dependencies

import DokoTypes
import DokoLogging
import DokoSharing

@DokoEngineActor
public final class ABRPManager: Sendable {
  private let logger = Logger(subsystem: "com.unchan.doko", category: "ABRPManager")

  public static let shared = ABRPManager()

  private let client = ABRPClient()
  private var lastSentAt: Date?
  private let minimumInterval: TimeInterval = 5.0

  private init() {}

  public func sendTripTelemetry(packet: DokoResponsePacket) {
    @Dependency(\.date.now) var now
    @Shared(.abrpEnabled) var enabled
    @Shared(.abrpUserToken) var userToken
    guard enabled, !userToken.isEmpty, shouldSend() else { return }

    var telemetry = ABRPTelemetry(utc: Int(now.timeIntervalSince1970))
    telemetry.soc = packet.batteryStateOfCharge
    telemetry.soh = packet.batteryStateOfHealth
    telemetry.battTemp = packet.batteryTemperature
    telemetry.power = packet.batteryPower
    telemetry.odometer = packet.odometer
    telemetry.isCharging = 0
    telemetry.isDCFC = 0
    telemetry.isParked = 0
    if let position = packet.position {
      telemetry.lat = position.latitude
      telemetry.lon = position.longitude
      telemetry.elevation = position.elevation
      telemetry.heading = position.course
      telemetry.speed = position.speed
    }
    if let weather = packet.weather {
      telemetry.extTemp = weather.temperature
    }

    Task { await send(telemetry: telemetry, userToken: userToken) }
  }

  public func sendChargeTelemetry(packet: DokoResponsePacket, isDCFC: Bool) {
    @Dependency(\.date.now) var now
    @Shared(.abrpEnabled) var enabled
    @Shared(.abrpUserToken) var userToken
    guard enabled, !userToken.isEmpty, shouldSend() else { return }

    var telemetry = ABRPTelemetry(utc: Int(now.timeIntervalSince1970))
    telemetry.soc = packet.batteryStateOfCharge
    telemetry.soh = packet.batteryStateOfHealth
    telemetry.battTemp = packet.batteryTemperature
    telemetry.power = packet.batteryPower
    telemetry.odometer = packet.odometer
    telemetry.isCharging = 1
    telemetry.isDCFC = isDCFC ? 1 : 0
    telemetry.isParked = 1
    if let position = packet.position {
      telemetry.lat = position.latitude
      telemetry.lon = position.longitude
      telemetry.elevation = position.elevation
    }
    if let weather = packet.weather {
      telemetry.extTemp = weather.temperature
    }

    Task { await send(telemetry: telemetry, userToken: userToken) }
  }

  private func shouldSend() -> Bool {
    @Dependency(\.date.now) var now
    guard let lastSentAt else { return true }
    return now.timeIntervalSince(lastSentAt) >= minimumInterval
  }

  private func send(telemetry: ABRPTelemetry, userToken: String) async {
    @Dependency(\.date.now) var now
    do {
      try await client.send(telemetry: telemetry, userToken: userToken)
      lastSentAt = now
      let socStr = telemetry.soc.map { String(format: "%.1f%%", $0) } ?? "nil"
      DokoLogging.shared.postLoggingResponse(.integration("ABRP.send ok soc=\(socStr)"))
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("ABRP.send: \(String(describing: error))"))
    }
  }
}
