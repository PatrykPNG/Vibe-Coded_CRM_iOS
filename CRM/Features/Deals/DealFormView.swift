import SwiftUI
import SwiftData

struct DealFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Contact.lastName) private var contacts: [Contact]

    var deal: Deal?

    @State private var title = ""
    @State private var value: Double = 0
    @State private var stage: DealStage = .lead
    @State private var notes = ""
    @State private var hasCloseDate = false
    @State private var closeDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    @State private var selectedContact: Contact?

    private var isEditing: Bool { deal != nil }
    private var isFormValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Deal") {
                    TextField("Title", text: $title)
                    HStack {
                        TextField("Value", value: $value, format: .number)
                            .keyboardType(.decimalPad)
                        Text("PLN")
                            .foregroundStyle(.secondary)
                    }
                    Picker("Stage", selection: $stage) {
                        ForEach(DealStage.allCases, id: \.self) { s in
                            Label(s.rawValue, systemImage: s.systemImage).tag(s)
                        }
                    }
                }

                Section("Contact") {
                    Picker("Linked Contact", selection: $selectedContact) {
                        Text("None").tag(nil as Contact?)
                        ForEach(contacts) { contact in
                            Text(contact.fullName).tag(contact as Contact?)
                        }
                    }
                }

                Section {
                    Toggle("Set Close Date", isOn: $hasCloseDate)
                    if hasCloseDate {
                        DatePicker("Close Date", selection: $closeDate, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(4...)
                }
            }
            .navigationTitle(isEditing ? "Edit Deal" : "New Deal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isFormValid)
                }
            }
            .onAppear { populateFields() }
        }
    }

    private func populateFields() {
        guard let deal else { return }
        title = deal.title
        value = deal.value
        stage = deal.stage
        notes = deal.notes
        selectedContact = deal.contact
        if let date = deal.closeDate {
            closeDate = date
            hasCloseDate = true
        }
    }

    private func save() {
        if let deal {
            deal.title = title
            deal.value = value
            deal.stage = stage
            deal.notes = notes
            deal.contact = selectedContact
            deal.closeDate = hasCloseDate ? closeDate : nil
        } else {
            let newDeal = Deal(
                title: title,
                value: value,
                stage: stage,
                notes: notes,
                closeDate: hasCloseDate ? closeDate : nil,
                contact: selectedContact
            )
            modelContext.insert(newDeal)
        }
        dismiss()
    }
}
