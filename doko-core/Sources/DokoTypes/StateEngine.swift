import Foundation

public struct StateEngineDokoCommandPacket: Sendable {
  public let schedulerType: StateEngineSchedulerType
  public let packetType: DokoPacketType

  public init(schedulerType: StateEngineSchedulerType, packetType: DokoPacketType) {
    self.schedulerType = schedulerType
    self.packetType = packetType
  }

  public enum StateEngineSchedulerType: Sendable {
    case oneShot
    case oneShotWithDelay(Double)
    case firesThenDelays(Double)
    case delaysThenFires(Double)
    
    public var description: String {
      switch self {
      case .oneShot:
        ".oneShot"
      case .oneShotWithDelay(let delay):
        "\(String(format: ".oneShotWithDelay(%.0f)", delay))"
      case .firesThenDelays(let delay):
        "\(String(format: ".firesThenDelays(%.0f)", delay))"
      case .delaysThenFires(let delay):
        "\(String(format: ".delaysThenFires(%.0f)", delay))"
      }
    }
  }
  
  public var description: String {
    "\(schedulerType.description)\(packetType.description)"
  }
}

public typealias StateEngineDokoSchedule = [StateEngineDokoCommandPacket]

extension [StateEngineDokoCommandPacket] {
  public var description: String {
    if count == 1 {
      return "\(self[0].description)"
    } else {
      return "\n  " + map { $0.description }.joined(separator: "\n  ") + "\n"
    }
  }
}
