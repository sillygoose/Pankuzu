import SwiftUI
import OSLog
import UniformTypeIdentifiers

import CasePaths
import SwiftUINavigation

import DokoSharing
import DokoSchema
import TripsUI
import ChargesUI
import CommonUI

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var deletedTripsExpanded: Self {
    Self[.appStorage("settingsDeletedTripsExpanded"), default: true]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var deletedChargesExpanded: Self {
    Self[.appStorage("settingsDeletedChargesExpanded"), default: true]
  }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
  static var databaseSaveRestoreExpanded: Self {
    Self[.appStorage("settingsDatabaseExpanded"), default: true]
  }
}

@MainActor @Observable class DatabaseSettingsModel {
  @ObservationIgnored @FetchAll(
    Trip
      .where { $0.isDeleted.eq(true) }
      .order { $0.deletedOrdering },
    animation: .default
  ) var deletedTrips
  
  @ObservationIgnored @FetchAll(
    Charge
      .where { $0.isDeleted.eq(true) }
      .order { $0.deletedOrdering },
    animation: .default
  ) var deletedCharges
  
  @CasePathable
  enum Destination {
    case alert(AlertState<AlertAction>)
  }
  enum AlertAction {
    case confirmDeleteDatabase
    case confirmDeleteTripsAndCharges
  }
  var destination: Destination?
  
  var selectedItems: Set<UUID> = []
  
  init(
    destination: Destination? = nil
  ) {
    self.destination = destination
  }

  @ObservationIgnored @Dependency(\.defaultDatabase) var database

  func alertButtonTapped(_ action: AlertAction?) async {
    switch action {
    case .confirmDeleteDatabase:
      do {
        try await database.write { db in
          try Vehicle.delete().execute(db)
        }
        try await database.write { db in
          try Location.delete().execute(db)
        }
        destination = .alert(.databaseCleared())
      } catch {
        destination = .alert(.databaseCleared(error.localizedDescription))
      }

    case .confirmDeleteTripsAndCharges:
      deleteSelectedItems()

    case nil:
      break
    }
  }

  func deleteSelectedItems() {
    deletedTrips.filter { selectedItems.contains($0.id) }
      .forEach { trip in
        withErrorReporting {
          try database.write { db in
            try Trip
              .find(trip.id)
              .delete()
              .execute(db)
          }
        }
      }
    deletedCharges.filter { selectedItems.contains($0.id) }
      .forEach { charge in
        withErrorReporting {
          try database.write { db in
            try Charge
              .find(charge.id)
              .delete()
              .execute(db)
          }
        }
      }
    selectedItems.removeAll()
  }
  
  func undeleteSelectedItems() {
    deletedTrips.filter { selectedItems.contains($0.id) }
      .forEach { trip in
        withErrorReporting {
          try database.write { db in
            try Trip
              .find(trip.id)
              .update { $0.deleted = #bind(nil) }
              .execute(db)
          }
        }
      }
    deletedCharges.filter { selectedItems.contains($0.id) }
      .forEach { charge in
        withErrorReporting {
          try database.write { db in
            try Charge
              .find(charge.id)
              .update { $0.deleted = #bind(nil) }
              .execute(db)
          }
        }
      }
    selectedItems.removeAll()
  }
}

struct DatabaseSettingsView: View {
  @Bindable var model: DatabaseSettingsModel
  
  @Environment(\.editMode) private var editMode
  
  @Shared(.deletedTripsExpanded) var deletedTripsExpanded
  @Shared(.deletedChargesExpanded) var deletedChargesExpanded
  @Shared(.databaseSaveRestoreExpanded) var databaseSaveRestoreExpanded
  @Shared(.appSettings) var appSettings

  @State var showFileImporter: Bool = false
  @State var showFileExporter: Bool = false
  @State var showBackupOptions: Bool = false
  @State var showRestoreOptions: Bool = false

  @State private var jsonDocument = JSONDocument(initialModel: DatabaseBackup())
  @State private var backupFilename: String?
  @State private var restoreFileURL: URL?
  @State private var backupOptions: BackupOptions = BackupOptions()
  @State private var restoreOptions: RestoreOptions = RestoreOptions()
  
  @Dependency(\.date.now) var now
  
  var body: some View {
    List(selection: $model.selectedItems) {
      Section {
        HStack {
          Button{
            backupOptions = BackupOptions(now: now)
            showBackupOptions = true
          } label: {
            HStack {
              Label("Backup", systemImage: "arrow.up.document.fill")
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
            restoreOptions = RestoreOptions()
            showRestoreOptions = true
          } label: {
            Label("Restore", systemImage: "arrow.down.document.fill")
              .font(.headline)
              .padding()
              .frame(maxWidth: .infinity)
              .background(Color.blue)
              .foregroundColor(.white)
              .cornerRadius(10)
          }
          .buttonStyle(.borderless)
        }

        HStack {
          Button{
            model.destination = .alert(.clearDatabase)
          } label: {
            HStack {
              Label("Clear Database", systemImage: "trash")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
          }
          .buttonStyle(.borderless)
        }
      }
      header: {
        Text("Backup or restore the database.")
      }
      
      Section {
        DisclosureGroup(
          isExpanded: Binding(
            get: { deletedTripsExpanded },
            set: { newValue in $deletedTripsExpanded.withLock { $0 = newValue } }
          )
        ) {
          ForEach(model.deletedTrips.enumerated(), id: \.element.id) { index, trip in
            NavigationLink(
              destination:
                TripDetailView(
                  model: TripDetailModel(tripID: trip.id)
                )
            ) {
              TripRow(trip: trip)
                .rowFormatter(index)
            }
          }
        } label: {
          Text("Deleted Trips (\(model.deletedTrips.count))")
            .font(.headline)
        }
      } footer: {
        Text("Deleted trips are available here for \(appSettings.deletedRecordRetentionDays) days. After that time, they will be permanently deleted.")
          .font(.caption)
      }

      Section {
        DisclosureGroup(
          isExpanded: Binding(
            get: { deletedChargesExpanded },
            set: { newValue in $deletedChargesExpanded.withLock { $0 = newValue } }
          )
        ) {
          ForEach(model.deletedCharges.enumerated(), id: \.element.id) { index, charge in
            NavigationLink(
              destination:
                ChargeDetailView(
                  model: ChargeDetailModel(chargeID: charge.id)
                )
            ) {
              ChargeRow(charge: charge)
                .rowFormatter(index)
            }
          }
        } label: {
          Text("Deleted Charges (\(model.deletedCharges.count))")
            .font(.headline)
        }
      } footer: {
        Text("Deleted charges are available here for \(appSettings.deletedRecordRetentionDays) days. After that time, they will be permanently deleted.")
          .font(.caption)
      }
    }
    .listStyle(.plain)
    .navigationTitle("Database")
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        let disableActionButtons = model.selectedItems.isEmpty || (model.deletedTrips.isEmpty && model.deletedCharges.isEmpty)
        EditButton()
          .disabled(model.deletedTrips.isEmpty && model.deletedCharges.isEmpty)
        
        if editMode?.wrappedValue == .active {
          Button {
            model.undeleteSelectedItems()
            editMode?.wrappedValue = .inactive
          } label: {
            Text("Restore")
            Image(systemName: "list.bullet.clipboard.fill")
          }
          .tint(.cyan)
          .disabled(disableActionButtons)
          
          Button {
            model.destination = .alert(.deleteTripsAndCharges)
          } label: {
            Text("Delete")
            Image(systemName: "trash.fill")
          }
          .tint(.red)
          .disabled(disableActionButtons)
        }
      }
    }
    .alert($model.destination.alert) { action in
      await model.alertButtonTapped(action)
      if action == .confirmDeleteTripsAndCharges {
        await MainActor.run { editMode?.wrappedValue = .inactive }
      }
    }
    .task(id: backupFilename) {
      guard let _ = backupFilename else { return }
      do {
        jsonDocument.backupModel = try backupDatabase(options: backupOptions)
        showFileExporter = true
      } catch {
        model.destination = .alert(.databaseBackup(error.localizedDescription))
      }
    }
    .task(id: restoreFileURL) {
      guard let restoreFileURL = restoreFileURL else { return }
      let accessing = restoreFileURL.startAccessingSecurityScopedResource()
      defer {
        if accessing {
          restoreFileURL.stopAccessingSecurityScopedResource()
        }
        self.restoreFileURL = nil
      }
      do {
        let data = try Data(contentsOf: restoreFileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDocument.backupModel = try decoder.decode(DatabaseBackup.self, from: data)
        try restoreDatabase(from: self.jsonDocument.backupModel, options: restoreOptions)
        model.destination = .alert(.databaseRestore())
      } catch {
        model.destination = .alert(.databaseRestore(error.localizedDescription))
      }
    }
    .sheet(isPresented: $showBackupOptions) {
      BackupOptionsView(options: $backupOptions) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: now)
        backupFilename = "Doko-\(dateString)"
      }
    }
    .sheet(isPresented: $showRestoreOptions) {
      RestoreOptionsView(options: $restoreOptions) {
        showFileImporter = true
      }
    }
    .fileExporter(
      isPresented: $showFileExporter,
      document: jsonDocument,
      contentType: .json,
      defaultFilename: backupFilename
    ) { result in
      switch result {
      case .success( _):
        model.destination = .alert(.databaseBackup())
      case .failure(let error):
        model.destination = .alert(.databaseBackup(error.localizedDescription))
      }
      backupFilename = nil
    }
    .fileImporter(
      isPresented: $showFileImporter,
      allowedContentTypes: [.json],
      allowsMultipleSelection: false
    ) { result in
      do {
        self.restoreFileURL = try result.get().first
      } catch {
        model.destination = .alert(.databaseRestore(error.localizedDescription))
      }
    }
    .onAppear {
      model.selectedItems = []
    }
  }
}

extension AlertState where Action == DatabaseSettingsModel.AlertAction {
  static func databaseBackup(_ errorMessage: String? = nil) -> Self {
    Self {
      TextState("Backup database")
    } actions: {
      ButtonState(role: .cancel) {
        TextState("Ok")
      }
    } message: {
      if let errorMessage = errorMessage {
        TextState("Database backup failed: \(errorMessage)")
      } else {
        TextState("Database backup completed")
      }
    }
  }

  static func databaseRestore(_ errorMessage: String? = nil) -> Self {
    Self {
      TextState("Restore database")
    } actions: {
      ButtonState(role: .cancel) {
        TextState("Ok")
      }
    } message: {
      if let errorMessage = errorMessage {
        TextState("Database restore failed: \(errorMessage)")
      } else {
        TextState("Database restore completed")
      }
    }
  }

  static func databaseCleared(_ errorMessage: String? = nil) -> Self {
    Self {
      TextState("Clear database")
    } actions: {
      ButtonState(role: .cancel) {
        TextState("Ok")
      }
    } message: {
      if let errorMessage = errorMessage {
        TextState("Database clear failed: \(errorMessage)")
      } else {
        TextState("Database clear completed")
      }
    }
  }

  static let deleteTripsAndCharges = Self {
    TextState("Delete?")
  } actions: {
    ButtonState(role: .destructive, action: .confirmDeleteTripsAndCharges) {
      TextState("Delete")
    }
    ButtonState(role: .cancel) {
      TextState("Cancel")
    }
  } message: {
    TextState(
      """
      Are you sure you want to permanently delete these trips and charges? \
      A backup will be required should you later change your mind.
      """
    )
  }

  static let clearDatabase = Self {
    TextState("Clear database?")
  } actions: {
    ButtonState(role: .destructive, action: .confirmDeleteDatabase) {
      TextState("Clear")
    }
    ButtonState(role: .cancel) {
      TextState("Cancel")
    }
  } message: {
    TextState(
      """
      Clearing the database is permanent. The only way to recover your trips and charges \
      is to restore from a backup.
      """
    )
  }
}

#Preview("Default") {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    DatabaseSettingsView(
      model: DatabaseSettingsModel()
    )
    .preferredColorScheme(.dark)
  }
}

#Preview("Edit Mode") {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    DatabaseSettingsView(
      model: DatabaseSettingsModel()
    )
    .environment(\.editMode, .constant(.active))
    .preferredColorScheme(.dark)
  }
}

#Preview("Trip/Charge Delete") {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    DatabaseSettingsView(
      model: DatabaseSettingsModel(
        destination: .alert(.deleteTripsAndCharges)
      )
    )
    .preferredColorScheme(.dark)
  }
}

#Preview("Database Deletion") {
  let _ = prepareDependencies {
    try? $0.bootstrapDatabase()
    try? $0.defaultDatabase.seedPreviews()
  }
  NavigationStack {
    DatabaseSettingsView(
      model: DatabaseSettingsModel(
        destination: .alert(.clearDatabase)
      )
    )
    .preferredColorScheme(.dark)
  }
}

private let logger = Logger(subsystem: "Doko", category: "DatabaseSettings")
