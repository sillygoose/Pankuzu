import Foundation

import Sharing

extension SharedKey where Self == InMemoryKey<String?>.Default {
  public static var connectedVehicleModel: Self {
    Self[.inMemory("DokoVehicleManager-ConnectedVehicleModel"), default: nil]
  }
}
