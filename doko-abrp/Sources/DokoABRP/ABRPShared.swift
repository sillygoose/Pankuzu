import Foundation

import Sharing

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  public static var abrpEnabled: Self {
    Self[.appStorage("ABRP-enabled"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<String>.Default {
  public static var abrpUserToken: Self {
    Self[.appStorage("ABRP-userToken"), default: ""]
  }
}
