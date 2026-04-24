import Foundation

import Sharing

extension SharedKey where Self == InMemoryKey<String?>.Default {
  public static var connectedAccessoryName: Self {
    Self[.inMemory("ObdLinkManager-AccessoryName"), default: nil]
  }
}

extension SharedKey where Self == InMemoryKey<String?>.Default {
  public static var connectedAccessorySerialNumber: Self {
    Self[.inMemory("ObdLinkManager-AccessorySerialNumber"), default: nil]
  }
}
