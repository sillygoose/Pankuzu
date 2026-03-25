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

//extension SharedKey where Self == AppStorageKey<Bool>.Default {
//  public static var backgroundMode: Self {
//    Self[.appStorage("ObdLinkManager-BackgroundMode"), default: false]
//  }
//}
//
//extension SharedKey where Self == AppStorageKey<String?>.Default {
//  public static var accessorySerialNumber: Self {
//    Self[.appStorage("ObdLinkManager-AccessorySerialNumber"), default: nil]
//  }
//}
