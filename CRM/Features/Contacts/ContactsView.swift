import SwiftUI
import SwiftData

struct ContactsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Contact.lastName) private var contacts: [Contact]

    @State private var searchText = ""
    @State private var showingAddContact = false

    private var filteredContacts: [Contact] {
        if searchText.isEmpty {
            contacts
        } else {
            contacts.filter {
                $0.fullName.localizedStandardContains(searchText) ||
                $0.company.localizedStandardContains(searchText) ||
                ($0.tags ?? []).contains { $0.name.localizedStandardContains(searchText) }
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredContacts) { contact in
                    NavigationLink(value: contact) {
                        ContactRowView(contact: contact)
                    }
                }
                .onDelete(perform: deleteContacts)
            }
            .navigationTitle("Contacts")
            .searchable(text: $searchText, prompt: "Search by name, company or tag")
            .navigationDestination(for: Contact.self) { contact in
                ContactDetailView(contact: contact)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Contact", systemImage: "plus") {
                        showingAddContact = true
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Load Sample Data", systemImage: "person.3") {
                        insertSampleData()
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                ContactFormView()
            }
            .overlay {
                if filteredContacts.isEmpty {
                    ContentUnavailableView {
                        Label(
                            searchText.isEmpty ? "No Contacts" : "No Results",
                            systemImage: searchText.isEmpty ? "person.crop.circle" : "magnifyingglass"
                        )
                    } description: {
                        Text(searchText.isEmpty
                             ? "Add your first contact using the + button."
                             : "No contacts match \"\(searchText)\".")
                    } actions: {
                        if searchText.isEmpty {
                            Button("Load Sample Data") {
                                insertSampleData()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        }
    }

    private func deleteContacts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredContacts[index])
        }
    }

    private func insertSampleData() {
        let lead = Tag(name: "Lead", color: .orange)
        let client = Tag(name: "Client", color: .green)
        let partner = Tag(name: "Partner", color: .blue)
        let vip = Tag(name: "VIP", color: .purple)
        [lead, client, partner, vip].forEach { modelContext.insert($0) }

        let sampleContacts: [(Contact, [Tag], [(InteractionType, TimeInterval, String)])] = [
            (
                Contact(firstName: "Alice", lastName: "Johnson", company: "Acme Corp",
                        email: "alice@acme.com", phone: "+1 555 0101",
                        notes: "Met at WWDC 2025. Very interested in enterprise plan."),
                [client, vip],
                [
                    (.meeting, -7, "Discussed Q1 roadmap and pricing"),
                    (.email, -2, "Sent revised proposal document"),
                    (.call, -1, "Quick check-in, she'll respond by Friday")
                ]
            ),
            (
                Contact(firstName: "Marco", lastName: "Rossi", company: "TechVentures",
                        email: "marco@techventures.io", phone: "+39 02 555 0182",
                        notes: "Intro via LinkedIn. Looking for a CRM solution for his 12-person team."),
                [lead],
                [
                    (.call, -14, "First discovery call — good fit"),
                    (.email, -10, "Sent product overview deck")
                ]
            ),
            (
                Contact(firstName: "Sophia", lastName: "Chen", company: "BrightPath",
                        email: "sophia@brightpath.co", phone: "+1 555 0247"),
                [partner],
                [
                    (.meeting, -30, "Partnership kickoff meeting"),
                    (.email, -20, "Signed NDA and partnership agreement"),
                    (.call, -5, "Quarterly check-in, all on track")
                ]
            ),
            (
                Contact(firstName: "James", lastName: "Okafor", company: "Okafor & Sons",
                        email: "james@okafor.com", phone: "+44 20 555 0193",
                        notes: "Long-term client. Renews every January."),
                [client],
                [
                    (.call, -60, "Annual review call"),
                    (.email, -45, "Sent renewal invoice"),
                    (.meeting, -3, "Coffee chat — happy with the service")
                ]
            ),
            (
                Contact(firstName: "Lena", lastName: "Müller", company: "NordFlow GmbH",
                        email: "lena@nordflow.de", phone: "+49 30 555 0137",
                        notes: "Hot lead from the Berlin conference."),
                [lead, vip],
                [
                    (.meeting, -4, "Demo session — very positive reaction"),
                    (.email, -1, "Followed up with case studies")
                ]
            )
        ]

        let (alice, marco, sophia, james, lena) = (
            sampleContacts[0].0,
            sampleContacts[1].0,
            sampleContacts[2].0,
            sampleContacts[3].0,
            sampleContacts[4].0
        )

        for (contact, tags, interactions) in sampleContacts {
            contact.tags = tags
            contact.interactions = interactions.map { type, offset, summary in
                Interaction(
                    type: type,
                    date: .now.addingTimeInterval(offset * 86400),
                    summary: summary,
                    contact: contact
                )
            }
            modelContext.insert(contact)
        }

        let sampleDeals: [Deal] = [
            Deal(title: "Acme Corp — Enterprise Plan",
                 value: 24_000,
                 stage: .negotiation,
                 notes: "Annual subscription, 50 seats. Legal review in progress.",
                 closeDate: .now.addingTimeInterval(14 * 86400),
                 contact: alice),
            Deal(title: "Acme Corp — Pro Add-on",
                 value: 4_800,
                 stage: .proposal,
                 notes: "Analytics module upsell. Waiting for sign-off.",
                 closeDate: .now.addingTimeInterval(30 * 86400),
                 contact: alice),
            Deal(title: "TechVentures — Starter Plan",
                 value: 6_000,
                 stage: .qualified,
                 notes: "12-person team, monthly billing preferred.",
                 closeDate: .now.addingTimeInterval(21 * 86400),
                 contact: marco),
            Deal(title: "BrightPath — Partnership Integration",
                 value: 15_000,
                 stage: .won,
                 notes: "Signed and live. Revenue share model.",
                 contact: sophia),
            Deal(title: "Okafor & Sons — Annual Renewal",
                 value: 9_600,
                 stage: .negotiation,
                 notes: "Renewing for 3rd year. Negotiating a 10% loyalty discount.",
                 closeDate: .now.addingTimeInterval(7 * 86400),
                 contact: james),
            Deal(title: "Okafor & Sons — Training Package",
                 value: 2_400,
                 stage: .proposal,
                 notes: "Onboarding for 3 new team members.",
                 contact: james),
            Deal(title: "NordFlow GmbH — Team Plan",
                 value: 18_000,
                 stage: .lead,
                 notes: "Very warm after the Berlin demo. Waiting for internal budget approval.",
                 closeDate: .now.addingTimeInterval(45 * 86400),
                 contact: lena),
            Deal(title: "NordFlow GmbH — Pilot",
                 value: 3_000,
                 stage: .lost,
                 notes: "Went with a competitor on price. Follow up in Q3.",
                 contact: lena)
        ]

        sampleDeals.forEach { modelContext.insert($0) }
    }
}

struct ContactRowView: View {
    let contact: Contact

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(contact.fullName)
                .bold()
            if !contact.company.isEmpty {
                Text(contact.company)
                    .foregroundStyle(.secondary)
            }
            if !(contact.tags ?? []).isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(contact.tags ?? []) { tag in
                            TagChipView(tag: tag)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Contact.self, Interaction.self, Tag.self,
        configurations: config
    )

    let client = Tag(name: "Client", color: .green)
    let lead = Tag(name: "Lead", color: .orange)
    let vip = Tag(name: "VIP", color: .purple)
    [client, lead, vip].forEach { container.mainContext.insert($0) }

    let alice = Contact(
        firstName: "Alice", lastName: "Johnson",
        company: "Acme Corp", email: "alice@acme.com", phone: "+1 555 0101"
    )
    alice.tags = [client, vip]
    alice.interactions = [
        Interaction(type: .meeting, date: .now.addingTimeInterval(-7 * 86400), summary: "Q1 roadmap discussion", contact: alice),
        Interaction(type: .email, date: .now.addingTimeInterval(-2 * 86400), summary: "Sent revised proposal", contact: alice)
    ]
    container.mainContext.insert(alice)

    let marco = Contact(
        firstName: "Marco", lastName: "Rossi",
        company: "TechVentures", email: "marco@techventures.io"
    )
    marco.tags = [lead]
    marco.interactions = [
        Interaction(type: .call, date: .now.addingTimeInterval(-14 * 86400), summary: "Discovery call — good fit", contact: marco)
    ]
    container.mainContext.insert(marco)

    let sophia = Contact(
        firstName: "Sophia", lastName: "Chen",
        company: "BrightPath", email: "sophia@brightpath.co"
    )
    container.mainContext.insert(sophia)

    return ContactsView()
        .modelContainer(container)
}

