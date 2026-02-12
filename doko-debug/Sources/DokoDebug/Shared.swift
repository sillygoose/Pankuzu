import Sharing

#if DEBUG
extension SharedKey where Self == InMemoryKey<Bool>.Default {
  public static var simIdle: Self {
    Self[.inMemory("DokoDebugShared-SimIdle"), default: false]
  }
}

extension SharedKey where Self == InMemoryKey<Bool>.Default {
  public static var simTrip: Self {
    Self[.inMemory("DokoDebugShared-SimTrip"), default: false]
  }
}

extension SharedKey where Self == InMemoryKey<Bool>.Default {
  public static var simAcCharge: Self {
    Self[.inMemory("DokoDebugShared-SimAcCharge"), default: false]
  }
}

extension SharedKey where Self == InMemoryKey<Bool>.Default {
  public static var simDcCharge: Self {
    Self[.inMemory("DokoDebugShared-SimDcCharge"), default: false]
  }
}
#endif
