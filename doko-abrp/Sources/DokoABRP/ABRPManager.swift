import Foundation
import OSLog

import DokoTypes
import DokoLogging
import Sharing

@DokoEngineActor
public final class ABRPManager: Sendable {
  private let logger = Logger(subsystem: "com.unchan.doko", category: "ABRPManager")

  public static let shared = ABRPManager()

  private let client = ABRPClient()
  private var lastSentAt: Date?
  private let minimumInterval: TimeInterval = 5.0

  private init() {}

  public func sendTripTelemetry(packet: DokoResponsePacket) async {
    @Shared(.abrpEnabled) var enabled
    @Shared(.abrpUserToken) var userToken
    guard enabled, !userToken.isEmpty, shouldSend() else { return }

    var telemetry = ABRPTelemetry(utc: Int(Date.now.timeIntervalSince1970))
    telemetry.soc = packet.stateOfCharge
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

    await send(telemetry: telemetry, userToken: userToken)
  }

  public func sendChargeTelemetry(packet: DokoResponsePacket, isDCFC: Bool) async {
    @Shared(.abrpEnabled) var enabled
    @Shared(.abrpUserToken) var userToken
    guard enabled, !userToken.isEmpty, shouldSend() else { return }

    var telemetry = ABRPTelemetry(utc: Int(Date.now.timeIntervalSince1970))
    telemetry.soc = packet.stateOfCharge
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

    await send(telemetry: telemetry, userToken: userToken)
  }

  private func shouldSend() -> Bool {
    guard let lastSentAt else { return true }
    return Date.now.timeIntervalSince(lastSentAt) >= minimumInterval
  }

  private func send(telemetry: ABRPTelemetry, userToken: String) async {
    do {
      try await client.send(telemetry: telemetry, userToken: userToken)
      lastSentAt = Date.now
      let socStr = telemetry.soc.map { String(format: "%.1f%%", $0) } ?? "nil"
      DokoLogging.shared.postLoggingResponse(.info("ABRP.send ok soc=\(socStr)"))
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("ABRP.send: \(String(describing: error))"))
    }
  }
}
