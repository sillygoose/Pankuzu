import SwiftUI
import OSLog

import DokoSharing
import DokoDebug
import DokoLogging
import DokoStateEngine
import DokoVehicleManager

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var loggingExpanded: Self {
    Self[.appStorage("Debugging-loggingExpanded"), default: false]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var simulationExpanded: Self {
    Self[.appStorage("Debugging-simulationExpanded"), default: false]
  }
}

@MainActor
@Observable
class DebuggingModel {
  private let logger = Logger(subsystem: "com.unchan.pankuzu", category: "Settings-Debugging")
  
  @ObservationIgnored @Shared(.connectedAccessoryName) var accessoryName
  @ObservationIgnored @Shared(.vehicleState) var vehicleState
  @ObservationIgnored @Shared(.activeSession) var activeSession
  
  var accessoryIsConnected: Bool { accessoryName != nil }
  
  @ObservationIgnored @Shared(.responseHistory) var responseHistory
  @ObservationIgnored @Shared(.logObdPackets) var logObdPackets
  @ObservationIgnored @Shared(.logDokoPackets) var logDokoPackets
  
  @ObservationIgnored @Shared(.logInfoPackets) var logInfoPackets
  @ObservationIgnored @Shared(.logStatePackets) var logStatePackets
  @ObservationIgnored @Shared(.logCoreLocationPackets) var logCoreLocationPackets
  @ObservationIgnored @Shared(.logLocationPackets) var logLocationPackets
  @ObservationIgnored @Shared(.logLiveActivityPackets) var logLiveActivityPackets
  @ObservationIgnored @Shared(.logPacketManagerPackets) var logPacketManagerPackets
  @ObservationIgnored @Shared(.logICloudPackets) var logICloudPackets
  
#if DEBUG
  @ObservationIgnored @Shared(.simIdle) var simIdle
  @ObservationIgnored @Shared(.simTrip) var simTrip
  @ObservationIgnored @Shared(.simAcCharge) var simAcCharge
  @ObservationIgnored @Shared(.simDcCharge) var simDcCharge
#endif
  
  var showCopyConfirmation = false
  
  init() {}
  
  func accessoryDidConnect(_ accessoryName: String) {
    self.logger.info("\(timestamp()) Settings.Debugging.accessoryDidConnect(\(accessoryName))")
  }
  
  func accessoryDidDisconnect() {
    self.logger.info("\(timestamp()) Settings.Debugging.accessoryDidDisconnect()")
#if DEBUG
    $simIdle.withLock { $0 = false }
    $simTrip.withLock { $0 = false }
    $simAcCharge.withLock { $0 = false }
    $simDcCharge.withLock { $0 = false }
#endif
  }
  
  func clearResponseHistory() {
    $responseHistory.withLock { $0 = [] }
  }
  
  func saveHistoryToClipboard() {
    let historyText = responseHistory.map { history in
      var text: String = ""
      switch history {
      case .logging(let responsePacket):
        text = "\(timestamp(responsePacket.completedAt)) \(responsePacket.type.description)"
      case .obd(let responsePacket):
        let responseCount = responsePacket.responses.count
        let response = responsePacket.responses.compactMap { _, response in "\(response.response.description) [\(response.rawCommand) → \(response.rawResponse)]" }.joined(separator: "\n  ")
        if responseCount < 2 {
          text = "\(timestamp(responsePacket.completedAt)) \(responsePacket.type.description)(\(response))"
        } else {
          text = "\(timestamp(responsePacket.completedAt)) \(responsePacket.type.description)(\n  \(response)\n)"
        }
        
      case .doko(let responsePacket):
        let responseCount = responsePacket.responses.count
        let response = responsePacket.responses.compactMap { _, response in response.response.description }.joined(separator: "\n  ")
        if responseCount < 2 {
          text = "\(timestamp(responsePacket.completedAt)) \(responsePacket.type.description)(\(response))"
        } else {
          text = "\(timestamp(responsePacket.completedAt)) \(responsePacket.type.description)(\n  \(response)\n)"
        }
      }
      return text
    }.joined(separator: "\n")
    let df = DateFormatter()
    df.locale = .current
    df.timeZone = .current
    df.dateStyle = .medium
    df.timeStyle = .medium
    df.doesRelativeDateFormatting = false
    let localTimestamp = df.string(from: Date())
    let displayName = AboutModel.displayName ?? "???"
    let version = AboutModel.version ?? "?.??"
    let build = AboutModel.build ?? "?"
    let shortHash = AboutModel.shortHash ?? "???"
    let branchName = AboutModel.branchName ?? "???"
    UIPasteboard.general.string = "\(displayName) \(version).\(build) \(branchName)(\(shortHash))\n\(localTimestamp)\n\n\(historyText)"
    showCopyConfirmation = true
  }
}

struct DebuggingView: View {
  @Bindable var model: DebuggingModel
  
  @Shared(.loggingExpanded) var loggingExpanded
  @Shared(.simulationExpanded) var simulationExpanded
  
#if DEBUG
  @Shared(.simIdle) var simIdle
  @Shared(.simTrip) var simTrip
  @Shared(.simAcCharge) var simAcCharge
  @Shared(.simDcCharge) var simDcCharge
  @Shared(.simVin) var simVin
#endif
  
  var body: some View {
    List {
      DisclosureGroup(
        isExpanded: Binding(
          get: { loggingExpanded },
          set: { newValue in $loggingExpanded.withLock { $0 = newValue } }
        )
      ) {
        Section {
          Toggle(
            "Application",
            isOn: Binding(
              get: { model.logDokoPackets },
              set: { isOn, _ in model.$logDokoPackets.withLock { $0 = isOn } }
            )
          )
          Toggle(
            "OBDLink Device",
            isOn: Binding(
              get: { model.logObdPackets },
              set: { isOn, _ in model.$logObdPackets.withLock { $0 = isOn } }
            )
          )
          Toggle(
            "Info",
            isOn: Binding(
              get: { model.logInfoPackets },
              set: { isOn, _ in model.$logInfoPackets.withLock { $0 = isOn } }
            )
          )
          Toggle(
            "State/Schedulers",
            isOn: Binding(
              get: { model.logStatePackets },
              set: { isOn, _ in model.$logStatePackets.withLock { $0 = isOn } }
            )
          )
          Toggle(
            "CoreLocation",
            isOn: Binding(
              get: { model.logCoreLocationPackets },
              set: { isOn, _ in model.$logCoreLocationPackets.withLock { $0 = isOn } }
            )
          )
          Toggle(
            "Location",
            isOn: Binding(
              get: { model.logLocationPackets },
              set: { isOn, _ in model.$logLocationPackets.withLock { $0 = isOn } }
            )
          )
          Toggle(
            "Live Activity",
            isOn: Binding(
              get: { model.logLiveActivityPackets },
              set: { isOn, _ in model.$logLiveActivityPackets.withLock { $0 = isOn } }
            )
          )
          Toggle(
            "Packet Manager",
            isOn: Binding(
              get: { model.logPacketManagerPackets },
              set: { isOn, _ in model.$logPacketManagerPackets.withLock { $0 = isOn } }
            )
          )
          Toggle(
            "iCloud",
            isOn: Binding(
              get: { model.logICloudPackets },
              set: { isOn, _ in model.$logICloudPackets.withLock { $0 = isOn } }
            )
          )
        } footer: {
          Text(
            "Enable log entries to help solve specific problems. Errors and connections are always logged but others should be disabled when not required."
          )
        }
      } label: {
        Text("Logging")
      }
      
#if DEBUG
      DisclosureGroup(
        isExpanded: Binding(
          get: { simulationExpanded },
          set: { newValue in $simulationExpanded.withLock { $0 = newValue } }
        )
      ) {
        VStack(alignment: .center, spacing: 20) {
          Picker(
            "Vehicle",
            selection: Binding(
              get: { simVin },
              set: { vin in $simVin.withLock { $0 = vin } }
            )
          ) {
            Text("2024 Ford F-150").tag("1FTVW3L76RWG00000")
            Text("2025 Mustang Mach-E").tag("3FMTK3SU6SMA40000")
            Text("2024 VW ID.4").tag("1V2DNPE81PC030000")
          }
          HStack(spacing: 30) {
            Toggle(
              "Idle",
              isOn: Binding(
                get: { simIdle },
                set: { isOn, _ in $simIdle.withLock { $0 = isOn } }
              )
            )
            .disabled(!model.accessoryIsConnected)
            Spacer()
            Toggle(
              "Trip",
              isOn: Binding(
                get: { simTrip },
                set: { isOn, _ in $simTrip.withLock { $0 = isOn } }
              )
            )
            .disabled(!DokoVehicleManager.shared.vehicleIsConnected || simAcCharge || simDcCharge)
          }
          HStack(spacing: 30) {
            Toggle(
              "AC Charge",
              isOn: Binding(
                get: { simAcCharge },
                set: { isOn, _ in $simAcCharge.withLock { $0 = isOn } }
              )
            )
            .disabled(!DokoVehicleManager.shared.vehicleIsConnected || simTrip || simDcCharge)
            Spacer()
            Toggle(
              "DC Charge",
              isOn: Binding(
                get: { simDcCharge },
                set: { isOn, _ in $simDcCharge.withLock { $0 = isOn } }
              )
            )
            .disabled(!DokoVehicleManager.shared.vehicleIsConnected || simTrip || simAcCharge)
          }
        }
        .padding([.top, .bottom], 10)
      } label: {
        Text("Simulation")
      }
#endif
      
      VStack {
        HStack {
          Button{
            model.saveHistoryToClipboard()
          } label: {
            HStack {
              Label("Copy", systemImage: "arrow.up.document.fill")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
          }
          .buttonStyle(.borderless)
          Spacer(minLength: 60)
          Button{
            model.clearResponseHistory()
          } label: {
            Label("Clear", systemImage: "arrow.down.document.fill")
              .font(.headline)
              .padding()
              .frame(maxWidth: .infinity)
              .background(Color.red)
              .foregroundColor(.white)
              .cornerRadius(10)
          }
          .buttonStyle(.borderless)
        }
        
        VStack(alignment: .leading, spacing: 0) {
          Text("History:")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
              ForEach(Array(model.responseHistory.enumerated()), id: \.offset) { _, history in
                switch history {
                case .logging(let responsePacket):
                  Text("\(timestamp(responsePacket.completedAt)) \(responsePacket.type.description)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                case .obd(let responsePacket):
                  let responseCount = responsePacket.responses.count
                  let response = responsePacket.responses
                    .compactMap { _, response in "\(response.response.description) [\(response.rawCommand) → \(response.rawResponse)]" }.joined(separator: "\n  ")
                  if responseCount < 2 {
                    Text("\(timestamp(responsePacket.completedAt)) \(responsePacket.type.description)(\(response))")
                      .frame(maxWidth: .infinity, alignment: .leading)
                  } else {
                    Text("\(timestamp(responsePacket.completedAt)) \(responsePacket.type.description)(\n  \(response)\n)")
                      .frame(maxWidth: .infinity, alignment: .leading)
                  }
                case .doko(let responsePacket):
                  let responseCount = responsePacket.responses.count
                  let response = responsePacket.responses
                    .compactMap { _, response in response.response.description }.joined(separator: "\n  ")
                  if responseCount < 2 {
                    Text("\(timestamp(responsePacket.completedAt)) \(responsePacket.type.description)(\(response))")
                      .frame(maxWidth: .infinity, alignment: .leading)
                  } else {
                    Text("\(timestamp(responsePacket.completedAt)) \(responsePacket.type.description)(\n  \(response)\n)")
                      .frame(maxWidth: .infinity, alignment: .leading)
                  }
                }
              }
            }
            .font(.system(.caption, design: .monospaced))
            .padding()
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .frame(maxHeight: 300)
          .background(Color(.secondarySystemBackground))
          .cornerRadius(8)
        }
      }
    }
    .listStyle(.plain)
    .navigationTitle("Debugging")
    .alert("Copied", isPresented: $model.showCopyConfirmation) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Copied to clipboard.")
    }
    .onChange(of: model.accessoryName) { _, newAccessoryName in
      if let accessoryName = newAccessoryName {
        model.accessoryDidConnect(accessoryName)
      } else {
        model.accessoryDidDisconnect()
      }
    }
  }
}

#Preview {
  NavigationStack {
    DebuggingView(
      model: DebuggingModel()
    )
    .preferredColorScheme(.dark)
  }
}
