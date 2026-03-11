import Foundation

import Sharing
import DequeModule

import DokoTypes
import ObdLinkCore

extension SharedKey where Self == InMemoryKey<Deque<DokoLoggingPacket>>.Default {
  public static var responseHistory: Self {
    Self[.inMemory("DokoLogging-ResponseHistory"), default: []]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var logObdPackets: Self {
    Self[.appStorage("DokoLogging-LogObdPackets"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var logDokoPackets: Self {
    Self[.appStorage("DokoLogging-LogDokoPackets"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var logInfoPackets: Self {
    Self[.appStorage("ApplicationSettings-logInfoPackets"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var logStatePackets: Self {
    Self[.appStorage("ApplicationSettings-logStatePackets"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var logCoreLocationPackets: Self {
    Self[.appStorage("ApplicationSettings-logCoreLocationPackets"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var logLocationPackets: Self {
    Self[.appStorage("ApplicationSettings-logLocationPackets"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var logLiveActivityPackets: Self {
    Self[.appStorage("ApplicationSettings-logLiveActivityPackets"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var logPacketManagerPackets: Self {
    Self[.appStorage("ApplicationSettings-logPacketManagerPackets"), default: false]
  }
}

