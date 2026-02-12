import Foundation

import Sharing

extension SharedKey where Self == InMemoryKey<String?>.Default {
  public static var connectedAccessory: Self {
    Self[.inMemory("ObdLinkManager-AccessoryName"), default: nil]
  }
}
