import Foundation
import OSLog

import Dependencies

import DokoTypes
import DokoLogging
import DokoSharing
import DokoVehicleManager

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
    @Shared(.appSettings) var appSettings
    guard appSettings.abrpEnabled else { return }
    guard let vin = DokoVehicleManager.shared.connectedVehicle?.vin,
          let userToken = appSettings.abrpVehicleTokens[vin],
          !userToken.isEmpty else {
      DokoLogging.shared.postLoggingResponse(.error("ABRP.sendTripTelemetry: no token"))
      return
    }
    guard shouldSend() else {
      DokoLogging.shared.postLoggingResponse(.error("ABRP.sendTripTelemetry: too soon"))
      return
    }

    var telemetry = ABRPTelemetry(utc: Int(now.timeIntervalSince1970))
    telemetry.soc = packet.batteryStateOfCharge
    telemetry.soh = packet.batteryStateOfHealth
    telemetry.battTemp = packet.batteryTemperature
    telemetry.power = packet.batteryPower.map { -$0 }
    telemetry.odometer = packet.odometer
    telemetry.speed = packet.speed
    telemetry.isCharging = 0
    telemetry.isDCFC = 0
    telemetry.isParked = 0
    if let position = packet.position {
      telemetry.lat = position.latitude
      telemetry.lon = position.longitude
    }
    if let weather = packet.weather {
      telemetry.extTemp = weather.temperature
    }

    Task { await send(telemetry: telemetry, userToken: userToken) }
  }

  public func sendChargeTelemetry(packet: DokoResponsePacket, isDCFC: Bool) {
    @Dependency(\.date.now) var now
    @Shared(.appSettings) var appSettings
    guard appSettings.abrpEnabled else { return }
    guard let vin = DokoVehicleManager.shared.connectedVehicle?.vin,
          let userToken = appSettings.abrpVehicleTokens[vin],
          !userToken.isEmpty else {
      DokoLogging.shared.postLoggingResponse(.error("ABRP.sendChargeTelemetry: no token"))
      return
    }
    guard shouldSend() else {
      DokoLogging.shared.postLoggingResponse(.error("ABRP.sendChargeTelemetry: too soon"))
      return
    }

    var telemetry = ABRPTelemetry(utc: Int(now.timeIntervalSince1970))
    telemetry.soc = packet.batteryStateOfCharge.map { floor($0) }
    telemetry.soh = packet.batteryStateOfHealth.map { floor($0) }
    telemetry.battTemp = packet.batteryTemperature.map { floor($0) }
    telemetry.power = packet.batteryPower.map { -$0 }
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
      DokoLogging.shared.postLoggingResponse(.integration("ABRP.send ok \(telemetry.description)"))
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("ABRP.send: \(String(describing: error))"))
    }
  }
}
