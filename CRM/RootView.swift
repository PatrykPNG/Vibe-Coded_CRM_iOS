import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "chart.bar.fill") {
                DashboardView()
            }
            Tab("Contacts", systemImage: "person.2") {
                ContactsView()
            }
            Tab("Deals", systemImage: "dollarsign.circle") {
                DealsView()
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Contact.self, Interaction.self, Tag.self, Deal.self,
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
    container.mainContext.insert(marco)

    let sophia = Contact(
        firstName: "Sophia", lastName: "Chen",
        company: "BrightPath", email: "sophia@brightpath.co"
    )
    container.mainContext.insert(sophia)

    let deals: [Deal] = [
        Deal(title: "Acme Corp — Enterprise Plan", value: 24_000, stage: .negotiation,
             closeDate: .now.addingTimeInterval(14 * 86400), contact: alice),
        Deal(title: "TechVentures — Starter Plan", value: 6_000, stage: .qualified,
             closeDate: .now.addingTimeInterval(21 * 86400), contact: marco),
        Deal(title: "BrightPath — Partnership", value: 15_000, stage: .won, contact: sophia)
    ]
    deals.forEach { container.mainContext.insert($0) }

    return RootView()
        .modelContainer(container)
}
