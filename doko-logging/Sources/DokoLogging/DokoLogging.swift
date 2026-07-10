import Foundation

import Dependencies

import DokoTypes
import ObdLinkCore

public enum DokoLoggingPacket: Sendable {
  case logging(LoggingResponsePacket)
  case obd(ObdResponsePacket)
  case doko(DokoResponsePacket)
}

public enum LoggingPacketType: Sendable {
  case info(String)
  case error(String)
  case state(String)
  case schedulers(String)
  case connect(String)
  case disconnect(String)
  case coreLocation(String)
  case location(String)
  case liveActivity(String)
  case packetManager(String)
  case iCloud(String)
  case integration(String)
  case database(String)

  public var description: String {
    switch self {
    case .info(let info): return ".info(\(info))"
    case .error(let error): return ".error(\(error))"
    case .state(let state): return ".state(\(state))"
    case .schedulers(let schedulers): return ".schedulers(\(schedulers))"
    case .connect(let connect): return ".connect(\(connect))"
    case .disconnect(let disconnect): return ".disconnect(\(disconnect))"
    case .coreLocation(let location): return ".coreLocation(\(location))"
    case .location(let location): return ".location(\(location))"
    case .liveActivity(let liveActivity): return ".liveActivity(\(liveActivity))"
    case .packetManager(let packetManager): return ".packetManager(\(packetManager))"
    case .iCloud(let iCloud): return ".iCloud(\(iCloud))"
    case .integration(let integration): return ".integration(\(integration))"
    case .database(let database): return ".database(\(database))"
    }
  }
}

public struct LoggingResponsePacket: Sendable {
  public let completedAt: Date
  public let type: LoggingPacketType

  public init(type: LoggingPacketType) {
    @Dependency(\.date.now) var now

    self.completedAt = now
    self.type = type
  }
}

public final class DokoLogging: Sendable {
  public static let shared = DokoLogging()
  
  private init() {}
  
  private func postResponse(_ response: DokoLoggingPacket, debugPacket: Bool) {
    @Shared(.responseHistory) var responseHistory
    @Shared(.logDebugPackets) var logDebugPackets
    @Shared(.logObdPackets) var logObdPackets
    @Shared(.logDokoPackets) var logDokoPackets
    @Shared(.logInfoPackets) var logInfoPackets
    @Shared(.logStatePackets) var logStatePackets
    @Shared(.logCoreLocationPackets) var logCoreLocationPackets
    @Shared(.logLocationPackets) var logLocationPackets
    @Shared(.logLiveActivityPackets) var logLiveActivityPackets
    @Shared(.logPacketManagerPackets) var logPacketManagerPackets
    @Shared(.logICloudPackets) var logICloudPackets
    @Shared(.logIntegrationPackets) var logIntegrationPackets
    @Shared(.logDatabasePackets) var logDatabasePackets

    switch response {
    case .logging(let packet):
      let shouldLog: Bool
      switch packet.type {
      case .error, .connect, .disconnect: shouldLog = true
      case .info: shouldLog = logInfoPackets
      case .coreLocation: shouldLog = logCoreLocationPackets
      case .location: shouldLog = logLocationPackets
      case .liveActivity: shouldLog = logLiveActivityPackets
      case .state, .schedulers: shouldLog = logStatePackets
      case .packetManager: shouldLog = logPacketManagerPackets
      case .iCloud: shouldLog = logICloudPackets
      case .integration: shouldLog = logIntegrationPackets
      case .database: shouldLog = logDatabasePackets
      }
      if shouldLog {
        if !debugPacket || logDebugPackets {
          $responseHistory.withLock { $0.prepend(response) }
        }
      }
    case .obd:
      if logObdPackets {
        if !debugPacket || logDebugPackets {
          $responseHistory.withLock { $0.prepend(response) }
        }
      }
    case .doko:
      if logDokoPackets {
        if !debugPacket || logDebugPackets {
          $responseHistory.withLock { $0.prepend(response) }
        }
      }
    }
  }

  public func postLoggingResponse(_ responsePacket: LoggingPacketType, debugPacket: Bool = false) {
    postResponse(.logging(LoggingResponsePacket(type: responsePacket)), debugPacket: debugPacket)
  }
}
