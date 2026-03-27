import SwiftData
import Foundation

@Model
final class Contact {
    var firstName: String = ""
    var lastName: String = ""
    var company: String = ""
    var email: String = ""
    var phone: String = ""
    var notes: String = ""
    var createdAt: Date = Date.now
    var reminderDate: Date?
    var reminderNote: String = ""
    var notificationID: UUID = UUID()
    @Relationship(deleteRule: .cascade, inverse: \Interaction.contact)
    var interactions: [Interaction]?
    @Relationship var tags: [Tag]?
    @Relationship(deleteRule: .nullify, inverse: \Deal.contact) var deals: [Deal]?

    init(
        firstName: String,
        lastName: String,
        company: String = "",
        email: String = "",
        phone: String = "",
        notes: String = ""
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.company = company
        self.email = email
        self.phone = phone
        self.notes = notes
        self.createdAt = .now
    }

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}
