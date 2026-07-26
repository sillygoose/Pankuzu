import SwiftUI

import DokoSharing

struct RestoreOptionsView: View {
  @Binding var options: RestoreOptions
  let onConfirm: () -> Void

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section("Restore") {
          Toggle("Trips", isOn: $options.includeTrips)
          Toggle("Charges", isOn: $options.includeCharges)
          Toggle("Settings", isOn: $options.includeSettings)
        }
      }
      .navigationTitle("Options")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Choose File") {
            onConfirm()
            dismiss()
          }
          .buttonStyle(.borderedProminent)
          .disabled(!options.includeTrips && !options.includeCharges && !options.includeSettings)
        }
      }
    }
  }
}

private enum DateRangeMode: String, CaseIterable {
  case all = "All"
  case today = "Today"
  case pastWeek = "Past Week"
  case custom = "Custom"
}

struct BackupOptionsView: View {
  @Binding var options: BackupOptions
  let onConfirm: () -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var dateRangeMode: DateRangeMode = .all
  @Shared(.appSettings) var appSettings

  var body: some View {
    NavigationStack {
      Form {
        Section("Backup") {
          Toggle("Trips", isOn: $options.includeTrips)
          Toggle("Charges", isOn: $options.includeCharges)
          Toggle("Settings", isOn: $options.includeSettings)
        }

        Section {
          Toggle(
            "Pretty Print Backup",
            isOn: Binding(
              get: { options.prettyPrint },
              set: { newValue in
                options.prettyPrint = newValue
                $appSettings.backupPrettyPrint.withLock { $0 = newValue }
              }
            )
          )
        } footer: {
          Text("Formats the backup file for human readability. Turning this off produces a smaller file.")
            .font(.caption)
        }

        Section {
          Picker("Date Range", selection: $dateRangeMode) {
            ForEach(DateRangeMode.allCases, id: \.self) { mode in
              Text(mode.rawValue).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .onChange(of: dateRangeMode) { _, mode in
            let cal = Calendar.current
            let now = Date()
            switch mode {
            case .all:
              options.useDateRange = false
            case .today:
              options.startDate = cal.startOfDay(for: now)
              options.endDate = now
              options.useDateRange = true
            case .pastWeek:
              options.startDate = cal.date(byAdding: .day, value: -7, to: cal.startOfDay(for: now)) ?? now
              options.endDate = now
              options.useDateRange = true
            case .custom:
              options.useDateRange = true
            }
          }
          if dateRangeMode == .custom {
            HStack {
              Text("From")
              Spacer()
              DatePicker("", selection: $options.startDate, in: ...min(options.endDate, Date()), displayedComponents: .date)
                .labelsHidden()
            }
            HStack {
              Text("Through")
              Spacer()
              DatePicker(
                "",
                selection: Binding(
                  get: { Calendar.current.date(byAdding: .day, value: -1, to: options.endDate) ?? options.endDate },
                  set: { options.endDate = $0 }
                ),
                in: options.startDate...Date(),
                displayedComponents: .date
              )
              .labelsHidden()
            }
          }
        } header: {
          Text("Backup Period")
        } footer: {
          if dateRangeMode != .all {
            Text("Only trips and charges that started within the selected range will be included.")
              .font(.caption)
          } else {
            Text("Backup all trips and chnarges.")
              .font(.caption)
          }
        }
      }
      .navigationTitle("Options")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Backup") {
            onConfirm()
            dismiss()
          }
          .buttonStyle(.borderedProminent)
          .disabled(!options.includeTrips && !options.includeCharges && !options.includeSettings)
        }
      }
    }
  }
}

#Preview("Backup") {
  @Previewable @State var options = BackupOptions()
  BackupOptionsView(options: $options) {}
    .preferredColorScheme(.dark)
}

#Preview("Restore") {
  @Previewable @State var options = RestoreOptions()
  RestoreOptionsView(options: $options) {}
    .preferredColorScheme(.dark)
}
