import Foundation
import ExternalAccessory
import Combine
import OSLog

import DokoTypes
import DokoLogging
import DokoSharing

@DokoEngineActor
public final class DokoPacketManager {
  enum PacketManagerError: Error, LocalizedError {
    case commandStreamExists, responseStreamExists
    var errorDescription: String {
      switch self {
      case .commandStreamExists:
        "command stream already exists"
      case .responseStreamExists:
        "response stream already exists"
      }
    }
  }
  
  private let logger = Logger(subsystem: "com.unchan.doko", category: "ObdLinkPacketManager")
  
  public static let shared = DokoPacketManager()
  
  private var dokoCommandStream: AsyncStream<DokoPacketType>?
  private var dokoCommandStreamContinuation: AsyncStream<DokoPacketType>.Continuation?

  private var dokoResponseStream: AsyncStream<DokoResponsePacket>?
  private var dokoResponseStreamContinuation: AsyncStream<DokoResponsePacket>.Continuation?
  
  private func startAccessoryNameObservation() {
    @Shared(.connectedAccessory) var observedAccessoryName
    Task { [weak self] in
      guard let self else { return }
      var oldAccessoryName: String? = nil
      for await newAccessoryName in $observedAccessoryName.publisher.values {
        if Task.isCancelled { break }
        if oldAccessoryName == newAccessoryName { continue }
        self.logger.info("\(timestamp()) ObdLinkPacketManager.EAAccessory changed from \(String(describing: oldAccessoryName)) to \(String(describing: newAccessoryName))")
        if newAccessoryName != nil {
          self.startStreams()
        } else {
          self.stopStreams()
        }
        oldAccessoryName = newAccessoryName
      }
    }
  }
  
  private init() {
    startAccessoryNameObservation()
  }
  
  private func startStreams() {
    startCommandStream()
    startResponseStream()
  }
  
  private func startCommandStream() {
    do {
      self.logger.debug("\(timestamp()) PM.startCommandStream")
      DokoLogging.shared.postLoggingResponse(.info("PM.startCommandStream"))
      guard dokoCommandStream == nil else { throw PacketManagerError.commandStreamExists }
      var dokoCommandContinuation: AsyncStream<DokoPacketType>.Continuation!
      self.dokoCommandStream = AsyncStream(bufferingPolicy: .unbounded) { continuation in
        dokoCommandContinuation = continuation
      }
      self.dokoCommandStreamContinuation = dokoCommandContinuation
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("PM.startCommandStream: \(error.localizedDescription)"))
    }
  }
  
  private func startResponseStream() {
    do {
      self.logger.debug("\(timestamp()) PM.startResponseStream")
      guard dokoResponseStream == nil else { throw PacketManagerError.responseStreamExists }
      DokoLogging.shared.postLoggingResponse(.info("PM.startResponseStream"))
      var rawResponseContinuation: AsyncStream<DokoResponsePacket>.Continuation!
      self.dokoResponseStream = AsyncStream(bufferingPolicy: .unbounded) { continuation in
        rawResponseContinuation = continuation
      }
      self.dokoResponseStreamContinuation = rawResponseContinuation
    } catch {
      DokoLogging.shared.postLoggingResponse(.error("PM.startResponseStream: \(String(describing: error))"))
    }
  }
  
  private func stopStreams() {
    self.logger.debug("\(timestamp()) PM.stopStreams")
    stopCommandStream()
    stopResponseStream()
  }
  
  private func stopCommandStream() {
    dokoCommandStreamContinuation?.finish()
    self.dokoCommandStreamContinuation = nil
    self.dokoCommandStream = nil
    self.logger.debug("\(timestamp()) PM.stopCommandStream")
    DokoLogging.shared.postLoggingResponse(.info("PM.stopCommandStream"))
  }
  
  private func stopResponseStream() {
    dokoResponseStreamContinuation?.finish()
    self.dokoResponseStreamContinuation = nil
    self.dokoResponseStream = nil
    self.logger.debug("\(timestamp()) PM.stopResponseStream")
    DokoLogging.shared.postLoggingResponse(.info("PM.stopResponseStream"))
  }
  
  public func appendDokoPacket(_ packet: DokoPacketType) async {
    self.logger.debug("\(timestamp()) ObdLinkPacketManager.appendDokoPacket(\(packet.description))")
    dokoCommandStreamContinuation?.yield(packet)
  }
  
  public func removeDokoPacket() async -> DokoPacketType? {
    guard let dokoCommandStream else { return nil }
    var iterator = dokoCommandStream.makeAsyncIterator()
    if let next = await iterator.next() { return next }
    return nil
  }
  
  public func appendDokoResponsePacket(_ responsePacket: DokoResponsePacket) {
    dokoResponseStreamContinuation?.yield(responsePacket)
  }

  public func removeDokoResponsePacket() async -> DokoResponsePacket? {
    guard let dokoResponseStream else { return nil }
    var iterator = dokoResponseStream.makeAsyncIterator()
    if let next = await iterator.next() {
      return next
    }
    return nil
  }
}
