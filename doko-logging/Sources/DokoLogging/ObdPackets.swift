import Foundation

import DokoTypes
import ObdLinkCore

extension DokoLogging {
  @DokoEngineActor public func postObdResponsePacket(responsePacket: ObdResponsePacket) {
    @Shared(.logObdPackets) var logObdPackets
    guard logObdPackets else { return }
      @Shared(.responseHistory) var responseHistory
      $responseHistory.withLock { $0.prepend(.obd(responsePacket)) }
  }
}
