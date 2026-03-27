import SwiftUI
import SwiftData

struct DealsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deal.createdAt, order: .reverse) private var deals: [Deal]

    @State private var searchText = ""
    @State private var showingAddDeal = false

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private var filteredDeals: [Deal] {
        guard !searchText.isEmpty else { return deals }
        return deals.filter {
            $0.title.localizedStandardContains(searchText) ||
            ($0.contact?.fullName.localizedStandardContains(searchText) ?? false)
        }
    }

    private var dealsByStage: [(DealStage, [Deal])] {
        DealStage.allCases.compactMap { stage in
            let stageDeals = filteredDeals.filter { $0.stage == stage }
            return stageDeals.isEmpty ? nil : (stage, stageDeals)
        }
    }

    private var activePipelineValue: Double {
        deals.filter(\.stage.isActive).reduce(0) { $0 + $1.value }
    }

    var body: some View {
        NavigationStack {
            List {
                if !deals.isEmpty && searchText.isEmpty {
                    Section {
                        HStack {
                            Text("Active Pipeline")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(activePipelineValue, format: .currency(code: currencyCode))
                                .bold()
                        }
                    }
                }

                ForEach(dealsByStage, id: \.0) { stage, stageDeals in
                    Section {
                        ForEach(stageDeals) { deal in
                            NavigationLink(value: deal) {
                                DealRowView(deal: deal)
                            }
                        }
                        .onDelete { offsets in deleteDeals(stageDeals, at: offsets) }
                    } header: {
                        HStack {
                            Label(stage.rawValue, systemImage: stage.systemImage)
                                .foregroundStyle(stage.color)
                            Spacer()
                            Text("\(stageDeals.count)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Deals")
            .searchable(text: $searchText, prompt: "Search by title or contact")
            .navigationDestination(for: Deal.self) { deal in
                DealDetailView(deal: deal)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Deal", systemImage: "plus") {
                        showingAddDeal = true
                    }
                }
            }
            .sheet(isPresented: $showingAddDeal) {
                DealFormView()
            }
            .overlay {
                if deals.isEmpty {
                    ContentUnavailableView(
                        "No Deals",
                        systemImage: "dollarsign.circle",
                        description: Text("Add your first deal using the + button.")
                    )
                }
            }
        }
    }

    private func deleteDeals(_ stageDeals: [Deal], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(stageDeals[index])
        }
    }
}

struct DealRowView: View {
    let deal: Deal

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private var isOverdue: Bool {
        guard let closeDate = deal.closeDate else { return false }
        return closeDate < .now && deal.stage.isActive
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(deal.title)
                .bold()
            HStack {
                if let contact = deal.contact {
                    Text(contact.fullName)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(deal.value, format: .currency(code: currencyCode))
                    .foregroundStyle(.secondary)
            }
            if let closeDate = deal.closeDate {
                Label(
                    "Close: \(closeDate.formatted(date: .abbreviated, time: .omitted))",
                    systemImage: isOverdue ? "exclamationmark.triangle.fill" : "calendar"
                )
                .font(.caption)
                .foregroundStyle(isOverdue ? .red : .secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
