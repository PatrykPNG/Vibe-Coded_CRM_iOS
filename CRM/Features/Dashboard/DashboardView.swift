import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var contacts: [Contact]
    @Query private var deals: [Deal]
    @Query(sort: \Interaction.date, order: .reverse) private var interactions: [Interaction]

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private var activeDeals: [Deal] { deals.filter(\.stage.isActive) }
    private var wonDeals: [Deal] { deals.filter { $0.stage == .won } }
    private var lostDeals: [Deal] { deals.filter { $0.stage == .lost } }

    private var activePipelineValue: Double {
        activeDeals.reduce(0) { $0 + $1.value }
    }

    private var winRate: Double {
        let closed = wonDeals.count + lostDeals.count
        guard closed > 0 else { return 0 }
        return Double(wonDeals.count) / Double(closed)
    }

    private var upcomingReminders: [Contact] {
        contacts
            .filter { $0.reminderDate != nil && $0.reminderDate! > .now }
            .sorted { $0.reminderDate! < $1.reminderDate! }
            .prefix(3)
            .map { $0 }
    }

    private var recentInteractions: [Interaction] {
        Array(interactions.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    PipelineSummaryCard(
                        activePipelineValue: activePipelineValue,
                        activeCount: activeDeals.count,
                        wonCount: wonDeals.count,
                        lostCount: lostDeals.count,
                        winRate: winRate,
                        contactCount: contacts.count,
                        currencyCode: currencyCode
                    )

                    if !deals.isEmpty {
                        StageBreakdownCard(deals: deals)
                    }

                    if !upcomingReminders.isEmpty {
                        UpcomingRemindersCard(contacts: upcomingReminders)
                    }

                    if !recentInteractions.isEmpty {
                        RecentActivityCard(interactions: recentInteractions)
                    }

                    if deals.isEmpty && contacts.isEmpty {
                        ContentUnavailableView(
                            "No Data Yet",
                            systemImage: "chart.bar",
                            description: Text("Add contacts and deals to see your dashboard.")
                        )
                        .padding(.top, 60)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .background(Color.primary.opacity(0.04))
        }
    }
}

// MARK: - Pipeline Summary Card

struct PipelineSummaryCard: View {
    let activePipelineValue: Double
    let activeCount: Int
    let wonCount: Int
    let lostCount: Int
    let winRate: Double
    let contactCount: Int
    let currencyCode: String

    var body: some View {
        DashboardCard(title: "Overview", systemImage: "chart.line.uptrend.xyaxis") {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activePipelineValue, format: .currency(code: currencyCode))
                        .font(.largeTitle)
                        .bold()
                    Text("\(activeCount) active deal\(activeCount == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(winRate, format: .percent.precision(.fractionLength(0)))
                        .font(.title2)
                        .bold()
                        .foregroundStyle(winRate > 0 ? .green : .secondary)
                    Text("win rate")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack(spacing: 24) {
                StatBadge(value: "\(contactCount)", label: "Contacts", systemImage: "person.2")
                StatBadge(value: "\(wonCount)", label: "Won", systemImage: "trophy.fill", color: .green)
                StatBadge(value: "\(lostCount)", label: "Lost", systemImage: "xmark.circle", color: .red)
            }
        }
    }
}

struct StatBadge: View {
    let value: String
    let label: String
    let systemImage: String
    var color: Color = .secondary

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
            Text(value)
                .bold()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Stage Breakdown Card

struct StageBreakdownCard: View {
    let deals: [Deal]

    private var breakdown: [(DealStage, Int)] {
        DealStage.allCases.compactMap { stage in
            let count = deals.filter { $0.stage == stage }.count
            return count > 0 ? (stage, count) : nil
        }
    }

    var body: some View {
        DashboardCard(title: "By Stage", systemImage: "chart.bar.fill") {
            ForEach(breakdown, id: \.0) { stage, count in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(stage.rawValue, systemImage: stage.systemImage)
                            .foregroundStyle(stage.color)
                        Spacer()
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    ProgressView(value: Double(count), total: Double(deals.count))
                        .tint(stage.color)
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Upcoming Reminders Card

struct UpcomingRemindersCard: View {
    let contacts: [Contact]

    var body: some View {
        DashboardCard(title: "Upcoming Reminders", systemImage: "bell.fill") {
            ForEach(contacts) { contact in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.fullName)
                            .bold()
                        if !contact.reminderNote.isEmpty {
                            Text(contact.reminderNote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    if let date = contact.reminderDate {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                            Text(date.formatted(date: .omitted, time: .shortened))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Recent Activity Card

struct RecentActivityCard: View {
    let interactions: [Interaction]

    var body: some View {
        DashboardCard(title: "Recent Activity", systemImage: "clock.fill") {
            ForEach(interactions) { interaction in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: interaction.type.systemImage)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(interaction.summary)
                            .lineLimit(2)
                        HStack {
                            if let name = interaction.contact?.fullName {
                                Text(name)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(interaction.date.formatted(date: .abbreviated, time: .omitted))
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Dashboard Card Container

struct DashboardCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(.rect(cornerRadius: 16))
    }
}
