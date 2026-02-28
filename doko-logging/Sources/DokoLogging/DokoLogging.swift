import Foundation

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
  case location(String)
  case liveActivity(String)
  case packetManager(String)

  public var description: String {
    switch self {
    case .info(let info): return ".info(\(info))"
    case .error(let error): return ".error(\(error))"
    case .state(let state): return ".state(\(state))"
    case .schedulers(let schedulers): return ".schedulers(\(schedulers))"
    case .connect(let connect): return ".connect(\(connect))"
    case .disconnect(let disconnect): return ".disconnect(\(disconnect))"
    case .location(let location): return ".location(\(location))"
    case .liveActivity(let liveActivity): return ".liveActivity(\(liveActivity))"
    case .packetManager(let packetManager): return ".packetManager(\(packetManager))"
    }
  }
}

public struct LoggingResponsePacket: Sendable {
  public let completedAt: Date
  public let type: LoggingPacketType

  public init(type: LoggingPacketType) {
    self.completedAt = Date.now
    self.type = type
  }
}

public final class DokoLogging: Sendable {
  public static let shared = DokoLogging()
  
  private init() {}
  
  private func postResponse(_ response: DokoLoggingPacket) {
    @Shared(.responseHistory) var responseHistory
    @Shared(.logObdPackets) var logObdPackets
    @Shared(.logDokoPackets) var logDokoPackets
    @Shared(.logInfoPackets) var logInfoPackets
    @Shared(.logStatePackets) var logStatePackets
    @Shared(.logLocationPackets) var logLocationPackets
    @Shared(.logLiveActivityPackets) var logLiveActivityPackets
    @Shared(.logPacketManagerPackets) var logPacketManagerPackets

    switch response {
    case .logging(let packet):
      let shouldLog: Bool
      switch packet.type {
      case .error, .connect, .disconnect: shouldLog = true
      case .info: shouldLog = logInfoPackets
      case .location: shouldLog = logLocationPackets
      case .liveActivity: shouldLog = logLiveActivityPackets
      case .state, .schedulers: shouldLog = logStatePackets
      case .packetManager: shouldLog = logPacketManagerPackets
      }
      if shouldLog {
        $responseHistory.withLock { $0.prepend(response) }
      }
    case .obd:
      if logObdPackets {
        $responseHistory.withLock { $0.prepend(response) }
      }
    case .doko:
      if logDokoPackets {
        $responseHistory.withLock { $0.prepend(response) }
      }
    }
  }

  public func postLoggingResponse(_ responsePacket: LoggingPacketType) {
    postResponse(.logging(LoggingResponsePacket(type: responsePacket)))
  }
}
