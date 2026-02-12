import SwiftUI

import DokoSharing

public struct SessionToolbar: ViewModifier {
  let connectedAccessory: String?
  let connectedVehicleModel: String?
  let activeSession: ActiveSession?

  public init(connectedAccessory: String? = nil, connectedVehicleModel: String? = nil, activeSession: ActiveSession? = nil) {
    self.connectedAccessory = connectedAccessory
    self.connectedVehicleModel = connectedVehicleModel
    self.activeSession = activeSession
  }

  public func body(content: Content) -> some View {
    content
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          if let activeSession {
            Image(systemName: activeSession.symbol)
              .foregroundStyle(.red)
              .symbolEffect(.pulse, options: .repeating)
          } else if connectedAccessory != nil {
            Image(systemName: "antenna.radiowaves.left.and.right")
              .foregroundStyle(.blue)
          }
        }
//        if let vehicleName = connectedVehicleModel {
//          ToolbarItem(placement: .principal) {
//            Text(vehicleName)
//              .font(.headline)
//              .lineLimit(1)
//              .truncationMode(.tail)
//          }
//        }
      }
  }
}

extension View {
  public func sessionToolbar(
    connectedAccessory: String?,
    connectedVehicleModel: String?,
    activeSession: ActiveSession?
  ) -> some View {
    modifier(SessionToolbar(
      connectedAccessory: connectedAccessory,
      connectedVehicleModel: connectedVehicleModel,
      activeSession: activeSession
    ))
  }
}
