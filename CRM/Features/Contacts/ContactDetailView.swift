import SwiftUI
import SwiftData

struct ContactDetailView: View {
    let contact: Contact

    @State private var showingEditContact = false
    @State private var showingAddInteraction = false
    @State private var showingReminderForm = false
    @State private var interactionToEdit: Interaction?

    private var sortedInteractions: [Interaction] {
        (contact.interactions ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            if !contact.company.isEmpty {
                Section("Company") {
                    Text(contact.company)
                }
            }

            if !contact.email.isEmpty || !contact.phone.isEmpty {
                Section("Contact Info") {
                    if !contact.email.isEmpty {
                        LabeledContent("Email", value: contact.email)
                    }
                    if !contact.phone.isEmpty {
                        LabeledContent("Phone", value: contact.phone)
                    }
                }
            }

            if !(contact.tags ?? []).isEmpty {
                Section("Tags") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(contact.tags ?? []) { tag in
                                TagChipView(tag: tag)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !contact.notes.isEmpty {
                Section("Notes") {
                    Text(contact.notes)
                }
            }

            if !(contact.deals ?? []).isEmpty {
                Section("Deals") {
                    ForEach((contact.deals ?? []).sorted { $0.createdAt > $1.createdAt }) { deal in
                        NavigationLink {
                            DealDetailView(deal: deal)
                        } label: {
                            HStack {
                                Label(deal.stage.rawValue, systemImage: deal.stage.systemImage)
                                    .foregroundStyle(deal.stage.color)
                                Spacer()
                                Text(
                                    deal.value,
                                    format: .currency(code: Locale.current.currency?.identifier ?? "USD")
                                )
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Reminder") {
                if let reminderDate = contact.reminderDate {
                    Label(reminderDate.formatted(date: .long, time: .shortened), systemImage: "bell.fill")
                        .foregroundStyle(reminderDate > .now ? .primary : .secondary)
                    if !contact.reminderNote.isEmpty {
                        Text(contact.reminderNote)
                            .foregroundStyle(.secondary)
                    }
                    Button("Edit Reminder") {
                        showingReminderForm = true
                    }
                } else {
                    Button("Set Reminder", systemImage: "bell") {
                        showingReminderForm = true
                    }
                }
            }

            Section {
                if sortedInteractions.isEmpty {
                    Text("No interactions yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedInteractions) { interaction in
                        InteractionRowView(interaction: interaction)
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    deleteInteraction(interaction)
                                }
                                Button("Edit") {
                                    interactionToEdit = interaction
                                }
                                .tint(.orange)
                            }
                    }
                }
            } header: {
                HStack {
                    Text("Interactions")
                    Spacer()
                    Button("Log", systemImage: "plus") {
                        showingAddInteraction = true
                    }
                    .labelStyle(.iconOnly)
                    .textCase(nil)
                }
            }

            Section {
                LabeledContent("Added", value: contact.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(contact.fullName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            Button("Edit") {
                showingEditContact = true
            }
        }
        .sheet(isPresented: $showingEditContact) {
            ContactFormView(contact: contact)
        }
        .sheet(isPresented: $showingAddInteraction) {
            InteractionFormView(contact: contact)
        }
        .sheet(item: $interactionToEdit) { interaction in
            InteractionFormView(contact: contact, interaction: interaction)
        }
        .sheet(isPresented: $showingReminderForm) {
            ReminderFormView(contact: contact)
        }
    }

    private func deleteInteraction(_ interaction: Interaction) {
        contact.interactions?.removeAll { $0.persistentModelID == interaction.persistentModelID }
    }
}

struct InteractionRowView: View {
    let interaction: Interaction

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: interaction.type.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(interaction.summary)
                Text(interaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
