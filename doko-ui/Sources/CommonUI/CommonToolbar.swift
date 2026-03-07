import SwiftUI

import DokoSharing

public struct SessionToolbar: ViewModifier {
  let connectedAccessoryName: String?
  let connectedVehicleModel: String?
  let activeSession: ActiveSession?

  public init(connectedAccessoryName: String? = nil, connectedVehicleModel: String? = nil, activeSession: ActiveSession? = nil) {
    self.connectedAccessoryName = connectedAccessoryName
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
          } else if connectedAccessoryName != nil {
            Image(systemName: "antenna.radiowaves.left.and.right")
              .foregroundStyle(.blue)
          }
        }
      }
  }
}

extension View {
  public func sessionToolbar(
    connectedAccessoryName: String?,
    connectedVehicleModel: String?,
    activeSession: ActiveSession?
  ) -> some View {
    modifier(SessionToolbar(
      connectedAccessoryName: connectedAccessoryName,
      connectedVehicleModel: connectedVehicleModel,
      activeSession: activeSession
    ))
  }
}
