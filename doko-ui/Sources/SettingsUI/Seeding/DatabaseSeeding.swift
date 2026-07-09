import SwiftUI
import OSLog

import Dependencies

import DokoSharing
import DokoSharing
import DokoLogging
import DokoStateEngine
import DokoVehicleManager
import CommonUI

public enum SeedingTimePeriod: String, CaseIterable, Identifiable, Sendable {
  case today
  case pastWeek
  case pastMonth

  public var id: Self { self }

  public var name: String {
    switch self {
    case .today: return "Today"
    case .pastWeek: return "Past Week"
    case .pastMonth: return "Past Month"
    }
  }
}

extension SharedKey where Self == AppStorageKey<SeedingTimePeriod>.Default {
  static var seedingTimePeriod: Self {
    Self[.appStorage("DatabaseSeeding-timePeriod"), default: .today]
  }
}

@MainActor
@Observable
class DatabaseSeedingModel {
  private let logger = Logger(subsystem: "com.unchan.pankuzu", category: "Settings-DatabaseSeeding")

  @ObservationIgnored @Shared(.seedingTimePeriod) var seedingTimePeriod
  
  init() {}

  func setSeedingTimePeriod(_ period: SeedingTimePeriod) {
    $seedingTimePeriod.withLock { $0 = period }
  }

  var dateWithinSelectedPeriod: Date {
    @Dependency(\.date.now) var now
    let calendar = Calendar.current

    switch seedingTimePeriod {
    case .today:
      let startOfDay = calendar.startOfDay(for: now)
      let secondsIntoDay = now.timeIntervalSince(startOfDay)
      let randomSeconds = Double.random(in: 0..<secondsIntoDay)
      return startOfDay.addingTimeInterval(randomSeconds)

    case .pastWeek:
      let daysAgo = Int.random(in: 0...6)
      let randomDay = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
      let startOfDay = calendar.startOfDay(for: randomDay)
      let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
      let maxTime = min(endOfDay, now)
      let randomSeconds = Double.random(in: 0..<maxTime.timeIntervalSince(startOfDay))
      return startOfDay.addingTimeInterval(randomSeconds)

    case .pastMonth:
      let daysAgo = Int.random(in: 0...29)
      let randomDay = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
      let startOfDay = calendar.startOfDay(for: randomDay)
      let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
      let maxTime = min(endOfDay, now)
      let randomSeconds = Double.random(in: 0..<maxTime.timeIntervalSince(startOfDay))
      return startOfDay.addingTimeInterval(randomSeconds)
    }
  }
}

struct DatabaseSeedingView: View {
  @Bindable var model: DatabaseSeedingModel

  @State private var showConfirmation = false
  @State private var confirmationMessage = ""

  var body: some View {
    List {
      Section {
        Picker(
          "Time Period",
          selection: Binding(
            get: { model.seedingTimePeriod },
            set: { model.setSeedingTimePeriod($0) }
          )
        ) {
          ForEach(SeedingTimePeriod.allCases) { period in
            Text(period.name).tag(period)
          }
        }
        .pickerStyle(.segmented)
      } header: {
        Text("Seed Date")
      } footer: {
        Text("Select the desired time period for the seed data.")
      }

      Section {
        Button {
          let seedDate = model.dateWithinSelectedPeriod
          model.seedTrip(tripStart: seedDate)
          confirmationMessage = "Trip created on \(seedDate.formatted(date: .abbreviated, time: .shortened))"
          showConfirmation = true
        } label: {
          Label("Seed Trip", systemImage: "car.fill")
        }
        .buttonStyle(DesignTokens.PrimaryButtonStyle())
      } header: {
        Text("Trip")
      } footer: {
        Text("Creates a sample trip with position, energy, and weather data.")
      }

      Section {
        Button {
          let seedDate = model.dateWithinSelectedPeriod
          model.seedAcCharge(chargeStart: seedDate)
          confirmationMessage = "AC Charge created on \(seedDate.formatted(date: .abbreviated, time: .shortened))"
          showConfirmation = true
        } label: {
          Label("Seed AC Charge", systemImage: "powerplug")
        }
        .buttonStyle(DesignTokens.PrimaryButtonStyle())
      } header: {
        Text("AC Charge")
      } footer: {
        Text("Creates a sample AC charging session with power curve data.")
      }

      Section {
        Button {
          let seedDate = model.dateWithinSelectedPeriod
          model.seedDcCharge(chargeStart: seedDate)
          confirmationMessage = "DC Charge created on \(seedDate.formatted(date: .abbreviated, time: .shortened))"
          showConfirmation = true
        } label: {
          Label("Seed DC Charge", systemImage: "ev.charger")
        }
        .buttonStyle(DesignTokens.PrimaryButtonStyle())
      } header: {
        Text("DC Charge")
      } footer: {
        Text("Creates a sample DC fast charging session with power curve data.")
      }
    }
    .alert("Seed Created", isPresented: $showConfirmation) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(confirmationMessage)
    }
    .listSectionSpacing(15)
    .navigationTitle("Database Seeding")
  }
}

#Preview {
  NavigationStack {
    DatabaseSeedingView(
      model: DatabaseSeedingModel()
    )
    .preferredColorScheme(.dark)
  }
}
