import Foundation

import Sharing
import DokoTypes

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

extension SharedKey where Self == InMemoryKey<DokoResponseDictionary>.Default {
  public static var chargeUpdateResponses: Self {
    Self[.inMemory("DokoUI-ChargeUpdateResponses"), default: [:]]
  }
}

extension SharedKey where Self == InMemoryKey<DokoResponseDictionary>.Default {
  public static var tripUpdateResponses: Self {
    Self[.inMemory("DokoUI-TripUpdateResponses"), default: [:]]
  }
}
