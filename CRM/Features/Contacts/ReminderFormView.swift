import SwiftUI

struct ReminderFormView: View {
    @Environment(\.dismiss) private var dismiss

    let contact: Contact

    @State private var date: Date
    @State private var note: String

    init(contact: Contact) {
        self.contact = contact
        let defaultDate = Calendar.current.date(
            bySettingHour: 9, minute: 0, second: 0,
            of: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        ) ?? .now
        _date = State(initialValue: contact.reminderDate ?? defaultDate)
        _note = State(initialValue: contact.reminderNote)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Date & Time",
                        selection: $date,
                        in: Date.now...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("Note") {
                    TextField("What to follow up about?", text: $note, axis: .vertical)
                        .lineLimit(3...)
                }

                if contact.reminderDate != nil {
                    Section {
                        Button("Clear Reminder", role: .destructive) {
                            clearReminder()
                        }
                    }
                }
            }
            .navigationTitle(contact.reminderDate == nil ? "Set Reminder" : "Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveReminder() }
                }
            }
        }
    }

    private func saveReminder() {
        NotificationService.shared.cancel(for: contact)
        contact.reminderDate = date
        contact.reminderNote = note
        NotificationService.shared.schedule(for: contact)
        dismiss()
    }

    private func clearReminder() {
        NotificationService.shared.cancel(for: contact)
        contact.reminderDate = nil
        contact.reminderNote = ""
        dismiss()
    }
}
