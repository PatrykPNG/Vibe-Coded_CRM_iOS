import SwiftUI
import SwiftData

struct InteractionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let contact: Contact
    var interaction: Interaction?

    @State private var type: InteractionType = .call
    @State private var date: Date = .now
    @State private var summary = ""

    private var isEditing: Bool { interaction != nil }
    private var isFormValid: Bool { !summary.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(InteractionType.allCases, id: \.self) { interactionType in
                            Label(interactionType.rawValue, systemImage: interactionType.systemImage)
                                .tag(interactionType)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Summary") {
                    TextField("What happened?", text: $summary, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .navigationTitle(isEditing ? "Edit Interaction" : "Log Interaction")
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
        guard let interaction else { return }
        type = interaction.type
        date = interaction.date
        summary = interaction.summary
    }

    private func save() {
        if let interaction {
            interaction.type = type
            interaction.date = date
            interaction.summary = summary
        } else {
            let newInteraction = Interaction(type: type, date: date, summary: summary, contact: contact)
            modelContext.insert(newInteraction)
        }
        dismiss()
    }
}
