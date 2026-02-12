import Foundation

import DokoTypes
import ObdLinkCore

extension DokoLogging {
//  @DokoEngineActor private static var previousByType: [DokoPacketType: ObdResponsePacket] = [:]
//  @DokoEngineActor private static func previousPacket(for type: DokoPacketType) -> ObdResponsePacket? { Self.previousByType[type] }
//  @DokoEngineActor private static func setPreviousPacket(_ packet: ObdResponsePacket?, for type: DokoPacketType) {
//    if let packet = packet {
//      Self.previousByType[type] = packet
//    } else {
//      Self.previousByType.removeValue(forKey: type)
//    }
//  }

  @DokoEngineActor public func postObdResponsePacket(responsePacket: ObdResponsePacket) {
    @Shared(.logObdPackets) var logObdPackets
    guard logObdPackets else { return }
//    var postPacket = true
//    switch responsePacket.type {
//    case .reset:
//      Self.previousByType.removeAll(keepingCapacity: false)
//    case .idle:
//      if let prev = Self.previousPacket(for: .idle) { postPacket = prev.responses != responsePacket.responses }
//      Self.setPreviousPacket(responsePacket, for: .idle)
//    case .tripInProgress:
//      if let prev = Self.previousPacket(for: .tripInProgress) { postPacket = prev.responses != responsePacket.responses }
//      Self.setPreviousPacket(responsePacket, for: .tripInProgress)
//    case .acChargeInProgress:
//      if let prev = Self.previousPacket(for: .acChargeInProgress) { postPacket = prev.responses != responsePacket.responses }
//      Self.setPreviousPacket(responsePacket, for: .acChargeInProgress)
//    case .dcChargeInProgress:
//      if let prev = Self.previousPacket(for: .dcChargeInProgress) { postPacket = prev.responses != responsePacket.responses }
//      Self.setPreviousPacket(responsePacket, for: .dcChargeInProgress)
//    default:
//      break
//    }
//    if postPacket {
      @Shared(.responseHistory) var responseHistory
      $responseHistory.withLock { $0.prepend(.obd(responsePacket)) }
//    }
  }
}
