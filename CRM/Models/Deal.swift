import SwiftUI
import SwiftData

enum DealStage: String, Codable, CaseIterable {
    case lead = "Lead"
    case qualified = "Qualified"
    case proposal = "Proposal"
    case negotiation = "Negotiation"
    case won = "Won"
    case lost = "Lost"

    var systemImage: String {
        switch self {
        case .lead: "sparkle"
        case .qualified: "scope"
        case .proposal: "doc.text"
        case .negotiation: "person.2"
        case .won: "trophy.fill"
        case .lost: "xmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .lead: .gray
        case .qualified: .blue
        case .proposal: .orange
        case .negotiation: .purple
        case .won: .green
        case .lost: .red
        }
    }

    var isActive: Bool { self != .won && self != .lost }
}

@Model
final class Deal {
    var title: String = ""
    var value: Double = 0
    var stage: DealStage = DealStage.lead
    var notes: String = ""
    var closeDate: Date?
    var contact: Contact?
    var createdAt: Date = Date.now

    init(
        title: String,
        value: Double = 0,
        stage: DealStage = .lead,
        notes: String = "",
        closeDate: Date? = nil,
        contact: Contact? = nil
    ) {
        self.title = title
        self.value = value
        self.stage = stage
        self.notes = notes
        self.closeDate = closeDate
        self.contact = contact
        self.createdAt = .now
    }
}
