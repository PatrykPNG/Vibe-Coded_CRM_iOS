import SwiftUI
import SwiftData

enum TagColor: String, Codable, CaseIterable {
    case red, orange, yellow, green, teal, blue, indigo, purple, pink, gray

    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .teal: .teal
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .gray: .gray
        }
    }

    var displayName: String { rawValue.capitalized }
}

@Model
final class Tag {
    var name: String = ""
    var color: TagColor = TagColor.gray
    @Relationship(inverse: \Contact.tags) var contacts: [Contact]?

    init(name: String, color: TagColor) {
        self.name = name
        self.color = color
    }
}
