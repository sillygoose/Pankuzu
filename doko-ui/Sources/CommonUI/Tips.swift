import TipKit

public struct WelcomeTip: Tip {
  public init() {}

  public var title: Text {
    Text("Seeding Sample Data")
  }

  public var message: Text? {
    Text("You can add sample trips and charges using the Add Trip/Charge button in the Settings tab - no OBDLink MX+ scan tool required.")
  }

  public var image: Image? {
    Image(systemName: "leaf")
  }
}

public struct CarPlayTip: Tip {
  public init() {}

  public var title: Text {
    Text("CarPlay Support")
  }

  public var message: Text? {
    Text("Enable Live Activities in CarPlay Settings and you can monitor your trip or charge in the CarPlay Home screen.\n\nBut because Live Activities can't be started from the background, you must bring Pankuzu briefly to the foreground to start Live Activities.😩")
  }

  public var image: Image? {
    Image(systemName: "car.front.waves.up")
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

public struct EditChargeDetailTip: Tip {
  public init() {}

  public var title: Text {
    Text("Edit Charge Details")
  }

  public var message: Text? {
    Text("You can update an incomplete charge by tapping the Edit button and entering the values from the Ford app.")
  }

  public var image: Image? {
    Image(systemName: "plus.circle")
  }
}

public struct ExploreAddMissingChargeTip: Tip {
  public init() {}

  public var title: Text {
    Text("Add Missing Charge")
  }

  public var message: Text? {
    Text("You can add a missing charge by tapping the Add Charge button and entering the values from the vehicle or charging app.")
  }

  public var image: Image? {
    Image(systemName: "ev.charger")
  }
}

public struct DebuggingTip: Tip {
  public init() {}

  public var title: Text {
    Text("Debug Log Shortcuts")
  }

  public var message: Text? {
    Text("Long press the Debugging button for shortcuts to copy and clear the debug log.")
  }

  public var image: Image? {
    Image(systemName: "ladybug.circle.fill")
  }
}

public struct ScanToolTip: Tip {
  public init() {}
  
  private var displayName: String {
    guard
      let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
    else { return "Pankuzu" }
    return "\(displayName)"
  }

  public var title: Text {
    Text("Manage the Scan Tool")
  }

  public var message: Text? {
    Text("Use the Scan Tool Status button to enable/disable background operation. This can also be acomplished using shortcuts or asking Siri to 'Enable \(displayName) background mode'")
  }

  public var image: Image? {
    Image(systemName: "exclamationmark.triangle")
  }
}
