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

extension SharedKey where Self == AppStorageKey<String>.Default {
  public static var widgetSession: Self {
    Self[.appStorage("widget-session", store: .pankuzu), default: ""]
  }
}

extension SharedKey where Self == InMemoryKey<DokoResponseDictionary>.Default {
  public static var chargeResponses: Self {
    Self[.inMemory("DokoUI-ChargeResponses"), default: [:]]
  }
}
