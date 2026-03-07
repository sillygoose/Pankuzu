import TipKit

public struct WelcomeTip: Tip {
  public init() {}

  public var title: Text {
    Text("Seeding Sample Data")
  }

  public var message: Text? {
    Text("You can add sample trips and charges using the Seed Database button in the Settings tab - no OBDLink MX+ scan tool required.")
  }

  public var image: Image? {
    Image(systemName: "leaf")
  }
}

public struct TripDetailsTip: Tip {
  public init() {}

  public var title: Text {
    Text("View Trip Details")
  }

  public var message: Text? {
    Text("Trips you have taken appear here, tap on any trip to see detailed information including route, elevation chnage, and weather conditions.")
  }

  public var image: Image? {
    Image(systemName: "map")
  }
}

public struct ChargeDetailsTip: Tip {
  public init() {}

  public var title: Text {
    Text("View Charge Details")
  }

  public var message: Text? {
    Text("Charges you have recorded will appear here, tap on any charge to see the charge details.")
  }

  public var image: Image? {
    Image(systemName: "ev.charger")
  }
}

public struct SettingsTip: Tip {
  public init() {}
  
  private var displayName: String {
    guard
      let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
    else { return "Pankuzu" }
    return "\(displayName)"
  }

  public var title: Text {
    Text("Configure Bluetooth")
  }

  public var message: Text? {
    Text("Use the Bluetooth settings to enable/disable background operation of \(displayName).")
  }

  public var image: Image? {
    Image(systemName: "exclamationmark.triangle")
  }
}
