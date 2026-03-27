import SwiftUI

struct TagChipView: View {
    let tag: Tag

    var body: some View {
        Text(tag.name)
            .font(.caption)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tag.color.color.opacity(0.2))
            .foregroundStyle(tag.color.color)
            .clipShape(.capsule)
    }
}
