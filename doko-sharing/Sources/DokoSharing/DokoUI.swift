import Foundation

import Sharing

public enum ActiveSession: String, Sendable {
  case trip
  case acCharge, dcCharge

  public var symbol: String {
    switch self {
    case .trip: return "car.rear.road.lane.dashed"
    case .acCharge: return "powerplug.fill"
    case .dcCharge: return "ev.charger.fill"
    }
  }
}

extension SharedKey where Self == InMemoryKey<ActiveSession?>.Default {
  public static var activeSession: Self {
    Self[.inMemory("DokoUI-ActiveSession"), default: nil]
  }
}
