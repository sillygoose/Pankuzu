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

public struct ExploreTabTip: Tip {
  public init() {}

  public var title: Text {
    Text("Explore")
  }

  let intro           = "Use the Explore your data in new and different ways:"
  let addMissing      = "- add missing charges from your vehicle or charging app"
  let editExiisting   = "- update a partial charge with the final values"
  let chargeHistory   = "- check out your charing history over the past year"
  let tripEfficiency  = "- see how much you drove and how your EV efficiency is changing with the weather"

  public var message: Text? {
    Text("\(intro)\n\n\(addMissing)\n\n\(editExiisting)\n\n\(chargeHistory)\n\n\(tripEfficiency)")
  }

  public var image: Image? {
    Image(systemName: "ev.charger")
  }
}

//public struct ExploreAddMissingChargeTip: Tip {
//  public init() {}
//
//  public var title: Text {
//    Text("Add Missing Charge")
//  }
//
//  public var message: Text? {
//    Text("You can add a missing charge by tapping the Add Missing Charge button and entering the values from the vehicle or charging app.")
//  }
//
//  public var image: Image? {
//    Image(systemName: "ev.charger")
//  }
//}
//
//public struct EditExistingChargeTip: Tip {
//  public init() {}
//
//  public var title: Text {
//    Text("Edit Existing Charge")
//  }
//
//  public var message: Text? {
//    Text("You can update an incomplete charge by tapping the Edit Exisiting Charge button and entering the values from the vehicle or charging app.")
//  }
//
//  public var image: Image? {
//    Image(systemName: "pencil")
//  }
//}
//
//public struct ChargeHistoryTip: Tip {
//  public init() {}
//
//  public var title: Text {
//    Text("Charge History")
//  }
//
//  public var message: Text? {
//    Text("Take a look at your charing history over the past year and see just how much energy you used.")
//  }
//
//  public var image: Image? {
//    Image(systemName: "calendar")
//  }
//}
//
//public struct TripEfficiencyTip: Tip {
//  public init() {}
//
//  public var title: Text {
//    Text("Trip Efficiency")
//  }
//
//  public var message: Text? {
//    Text("Wondering how much you drove and how your EV efficiency is changing with the weather? Check it all out in the Trip Efficiency charts.")
//  }
//
//  public var image: Image? {
//    Image(systemName: "leaf.fill")
//  }
//}

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
