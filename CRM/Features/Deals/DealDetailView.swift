import SwiftUI

struct DealDetailView: View {
    let deal: Deal

    @State private var showingEditDeal = false

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private var isOverdue: Bool {
        guard let closeDate = deal.closeDate else { return false }
        return closeDate < .now && deal.stage.isActive
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Label(deal.stage.rawValue, systemImage: deal.stage.systemImage)
                        .foregroundStyle(deal.stage.color)
                    Spacer()
                    Text(deal.value, format: .currency(code: currencyCode))
                        .bold()
                        .font(.title3)
                }
            }

            if let contact = deal.contact {
                Section("Contact") {
                    NavigationLink {
                        ContactDetailView(contact: contact)
                    } label: {
                        Text(contact.fullName)
                    }
                }
            }

            if let closeDate = deal.closeDate {
                Section("Expected Close") {
                    Label(
                        closeDate.formatted(date: .long, time: .omitted),
                        systemImage: isOverdue ? "exclamationmark.triangle.fill" : "calendar"
                    )
                    .foregroundStyle(isOverdue ? .red : .primary)
                }
            }

            if !deal.notes.isEmpty {
                Section("Notes") {
                    Text(deal.notes)
                }
            }

            Section {
                LabeledContent("Created", value: deal.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(deal.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            Button("Edit") {
                showingEditDeal = true
            }
        }
        .sheet(isPresented: $showingEditDeal) {
            DealFormView(deal: deal)
        }
    }
}
