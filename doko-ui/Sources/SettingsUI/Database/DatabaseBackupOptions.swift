import SwiftUI

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
          .disabled(!options.includeTrips && !options.includeCharges && !options.includeSettings)
        }
      }
    }
  }
}

struct BackupOptionsView: View {
  @Binding var options: BackupOptions
  let onConfirm: () -> Void

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section("Backup") {
          Toggle("Trips", isOn: $options.includeTrips)
          Toggle("Charges", isOn: $options.includeCharges)
          Toggle("Settings", isOn: $options.includeSettings)
        }

        Section {
          Toggle("Limit to Date Range", isOn: $options.useDateRange)
          if options.useDateRange {
            DatePicker(
              "From",
              selection: $options.startDate,
              in: ...options.endDate,
              displayedComponents: .date
            )
            DatePicker(
              "To",
              selection: Binding(
                get: { Calendar.current.date(byAdding: .day, value: -1, to: options.endDate) ?? options.endDate },
                set: { options.endDate = $0 }
              ),
              in: options.startDate...,
              displayedComponents: .date
            )
          }
        } footer: {
          if options.useDateRange {
            Text("Only trips and charges that started within the selected range will be included.")
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
