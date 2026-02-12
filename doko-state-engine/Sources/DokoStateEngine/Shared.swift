import Sharing

import DokoTypes

extension SharedKey where Self == InMemoryKey<VehicleState>.Default {
  public static var vehicleState: Self {
    Self[.inMemory("StateManager-VehicleState"), default: .reset]
  }
}
