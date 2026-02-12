import Foundation

import DokoTypes

extension DokoLogging {
//  @DokoEngineActor private static var previousByType: [DokoPacketType: DokoResponsePacket] = [:]
//  @DokoEngineActor private static func previousPacket(for type: DokoPacketType) -> DokoResponsePacket? { Self.previousByType[type] }
//  @DokoEngineActor private static func setPreviousPacket(_ packet: DokoResponsePacket?, for type: DokoPacketType) {
//    if let packet = packet {
//      Self.previousByType[type] = packet
//    } else {
//      Self.previousByType.removeValue(forKey: type)
//    }
//  }

  @DokoEngineActor public func postDokoResponsePacket(responsePacket: DokoResponsePacket) {
    @Shared(.logDokoPackets) var logDokoPackets
    guard logDokoPackets else { return }
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
//    @Shared(.filterPackets) var filterPackets
//    if postPacket {
      @Shared(.responseHistory) var responseHistory
      $responseHistory.withLock { $0.prepend(.doko(responsePacket)) }
//    }
  }
}
