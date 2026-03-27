import SwiftData
import Foundation

enum InteractionType: String, Codable, CaseIterable {
    case call = "Call"
    case email = "Email"
    case meeting = "Meeting"
    case note = "Note"

    var systemImage: String {
        switch self {
        case .call: "phone"
        case .email: "envelope"
        case .meeting: "person.2"
        case .note: "note.text"
        }
    }
}

@Model
final class Interaction {
    var type: InteractionType = InteractionType.note
    var date: Date = Date.now
    var summary: String = ""
    var contact: Contact?

    init(type: InteractionType, date: Date = .now, summary: String, contact: Contact? = nil) {
        self.type = type
        self.date = date
        self.summary = summary
        self.contact = contact
    }
}
