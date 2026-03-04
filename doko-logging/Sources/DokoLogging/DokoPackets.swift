import Foundation

import DokoTypes

extension DokoLogging {
  @DokoEngineActor public func postDokoResponsePacket(responsePacket: DokoResponsePacket) {
    @Shared(.logDokoPackets) var logDokoPackets
    guard logDokoPackets else { return }
      @Shared(.responseHistory) var responseHistory
      $responseHistory.withLock { $0.prepend(.doko(responsePacket)) }
  }
}
